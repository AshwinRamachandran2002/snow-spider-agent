/* Build one row per accident that involved >1 person
   and add features + label indicating whether the accident
   resulted in >1 fatalities                                         */

WITH person_counts AS (
  -- Count persons and fatal persons per crash; keep only crashes with >1 person
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                                   AS persons_in_accident,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)           AS fatal_persons
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING persons_in_accident > 1
),
vehicle_stats AS (
  /* Aggregate vehicle-level data to crash level
     · choose an arbitrary body_type (MIN used as deterministic pick)
     · compute average |travel_speed – speed_limit| for usable codes        */
  SELECT
    state_number,
    consecutive_number,
    MIN(body_type)                                                AS body_type,
    AVG(ABS(travel_speed - speed_limit))                          AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151      -- exclude 997/998/999
    AND speed_limit   BETWEEN 5 AND 80      -- exclude 98/99
  GROUP BY state_number, consecutive_number
),
accident_base AS (
  -- Accident-level predictors
  SELECT
    state_number,
    consecutive_number,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    CASE WHEN work_zone = 'None' THEN 0 ELSE 1 END AS work_zone_indicator
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)

SELECT
  pc.state_number,                       -- predictor 1
  vs.body_type,                          -- predictor 2
  ab.number_of_drunk_drivers,            -- predictor 3
  ab.day_of_week,                        -- predictor 4
  ab.hour_of_crash,                      -- predictor 5
  ab.work_zone_indicator,                -- predictor 6

  -- engineered feature: binned average speed difference (20-mph bins)
  CASE
    WHEN vs.avg_speed_diff IS NULL THEN NULL
    WHEN vs.avg_speed_diff < 20  THEN 0
    WHEN vs.avg_speed_diff < 40  THEN 1
    WHEN vs.avg_speed_diff < 60  THEN 2
    WHEN vs.avg_speed_diff < 80  THEN 3
    ELSE 4
  END AS speed_diff_level,

  -- target label: 1 if >1 fatal persons, else 0
  CASE WHEN pc.fatal_persons > 1 THEN 1 ELSE 0 END AS label
FROM person_counts      AS pc
JOIN accident_base      AS ab USING (state_number, consecutive_number)
LEFT JOIN vehicle_stats AS vs USING (state_number, consecutive_number);