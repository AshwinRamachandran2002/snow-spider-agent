WITH person_counts AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                                   AS num_persons,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)            AS num_fatal_injuries
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),

vehicle_speed AS (
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151            -- exclude 997‑999 codes
    AND speed_limit BETWEEN 0 AND 80              -- exclude 98‑99 codes
  GROUP BY state_number, consecutive_number
),

body_type_per_accident AS (
  SELECT
    state_number,
    consecutive_number,
    MIN(body_type) AS body_type                   -- use first (min) body‑type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
)

SELECT
  a.state_number,
  bt.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  CASE WHEN CAST(a.work_zone AS STRING) = '0' THEN 0 ELSE 1 END      AS work_zone_ind,
  CASE
    WHEN vs.avg_speed_diff IS NULL     THEN NULL
    WHEN vs.avg_speed_diff < 20        THEN 0
    WHEN vs.avg_speed_diff < 40        THEN 1
    WHEN vs.avg_speed_diff < 60        THEN 2
    WHEN vs.avg_speed_diff < 80        THEN 3
    ELSE 4
  END                                                               AS avg_speed_diff_lvl,
  CASE WHEN pc.num_fatal_injuries > 1 THEN 1 ELSE 0 END             AS label
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` a
JOIN person_counts          pc ON a.state_number = pc.state_number
                               AND a.consecutive_number = pc.consecutive_number
JOIN body_type_per_accident bt ON a.state_number = bt.state_number
                               AND a.consecutive_number = bt.consecutive_number
LEFT JOIN vehicle_speed     vs ON a.state_number = vs.state_number
                               AND a.consecutive_number = vs.consecutive_number
WHERE pc.num_persons > 1;