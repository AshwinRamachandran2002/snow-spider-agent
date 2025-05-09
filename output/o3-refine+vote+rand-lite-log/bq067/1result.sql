/* Create one record per 2016 accident with engineered predictors and binary label */
WITH person_stats AS (        -- number of persons and fatalities per crash
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                                   AS persons_in_crash,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END)           AS fatal_injuries
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),
vehicle_body AS (             -- representative body_type for each crash
  SELECT
    state_number,
    consecutive_number,
    ANY_VALUE(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
),
speed_diff AS (               -- average |travel_speed - speed_limit| with quality filters
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_abs_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed IS NOT NULL
    AND travel_speed NOT IN (997, 998, 999)
    AND travel_speed <= 151
    AND speed_limit IS NOT NULL
    AND speed_limit NOT IN (98, 99)
    AND speed_limit <= 80
  GROUP BY state_number, consecutive_number
),
speed_bucket AS (             -- bucket the average speed difference into 0–4 (20‑mph bins)
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_abs_speed_diff < 20 THEN 0
      WHEN avg_abs_speed_diff < 40 THEN 1
      WHEN avg_abs_speed_diff < 60 THEN 2
      WHEN avg_abs_speed_diff < 80 THEN 3
      ELSE 4
    END AS speed_diff_level
  FROM speed_diff
),
accident_feats AS (           -- pull required predictors from accident table
  SELECT
    state_number,
    consecutive_number,
    number_of_drunk_drivers,
    day_of_week,
    hour_of_crash,
    CASE
      WHEN SAFE_CAST(work_zone AS INT64) IS NULL
           OR SAFE_CAST(work_zone AS INT64) = 0 THEN 0
      ELSE 1
    END AS work_zone_flag
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
)

SELECT
  acc.state_number,
  vb.body_type,
  acc.number_of_drunk_drivers,
  acc.day_of_week,
  acc.hour_of_crash,
  acc.work_zone_flag,
  COALESCE(sb.speed_diff_level, 0)                      AS speed_diff_level,
  CASE WHEN ps.fatal_injuries > 1 THEN 1 ELSE 0 END     AS label
FROM accident_feats acc
JOIN person_stats  ps ON acc.state_number = ps.state_number
                     AND acc.consecutive_number = ps.consecutive_number
JOIN vehicle_body  vb ON acc.state_number = vb.state_number
                     AND acc.consecutive_number = vb.consecutive_number
LEFT JOIN speed_bucket sb ON acc.state_number = sb.state_number
                          AND acc.consecutive_number = sb.consecutive_number
WHERE ps.persons_in_crash > 1;      -- only crashes involving more than one person