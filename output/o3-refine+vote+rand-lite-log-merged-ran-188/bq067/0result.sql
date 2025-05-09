WITH person_counts AS (   -- crashes that involve >1 person & count fatalities
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                         AS num_persons,
    COUNTIF(injury_severity = 4)                          AS fatal_persons
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING num_persons > 1
),
vehicle_stats AS (        -- per-crash body type & avg |speed − limit|
  SELECT
    state_number,
    consecutive_number,
    ANY_VALUE(body_type)                                 AS body_type,
    AVG(ABS(travel_speed - speed_limit))                 AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151                  -- keep only valid coded speeds
    AND speed_limit  BETWEEN 5 AND 80                   -- keep only valid coded limits
  GROUP BY state_number, consecutive_number
),
accident_feats AS (       -- basic accident-level predictors
  SELECT
    state_number,
    consecutive_number,
    day_of_week,
    hour_of_crash,
    number_of_drunk_drivers,
    CASE WHEN work_zone = 'None' THEN 0 ELSE 1 END       AS is_work_zone
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)
SELECT
  pc.state_number,
  pc.consecutive_number,
  v.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  a.is_work_zone,
  v.avg_speed_diff,
  CASE                                                     -- 0-4 bucket of avg speed delta
    WHEN v.avg_speed_diff IS NULL THEN NULL
    WHEN v.avg_speed_diff < 20  THEN 0
    WHEN v.avg_speed_diff < 40  THEN 1
    WHEN v.avg_speed_diff < 60  THEN 2
    WHEN v.avg_speed_diff < 80  THEN 3
    ELSE 4
  END AS speed_diff_level,
  CASE WHEN pc.fatal_persons > 1 THEN 1 ELSE 0 END        AS label
FROM person_counts   pc
JOIN accident_feats  a USING (state_number, consecutive_number)
LEFT JOIN vehicle_stats v USING (state_number, consecutive_number);