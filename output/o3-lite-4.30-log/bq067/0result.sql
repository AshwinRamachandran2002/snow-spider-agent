/* Labeled crash‑level dataset (one row per accident) */
WITH person_stats AS (         -- crashes with >1 distinct person
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)            AS persons_in_crash,
    COUNTIF(injury_severity = 4)             AS fatalities_in_crash
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING persons_in_crash > 1
),
speed_feature AS (             -- average |travel_speed−speed_limit| per crash
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit))     AS avg_abs_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151       -- exclude codes 997‑999
    AND speed_limit  BETWEEN 5 AND 80        -- exclude codes 0,98,99
  GROUP BY state_number, consecutive_number
),
speed_bucket AS (              -- bucketised speed‑difference feature (0‑4)
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
  FROM speed_feature
),
vehicle_body AS (              -- select one body_type per crash
  SELECT
    state_number,
    consecutive_number,
    ANY_VALUE(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
)
SELECT
  -- label: 1 if >1 fatality in the crash, else 0
  CASE WHEN ps.fatalities_in_crash > 1 THEN 1 ELSE 0 END      AS label,
  a.state_number,
  vb.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  CASE WHEN a.work_zone = 'None' OR a.work_zone IS NULL
       THEN 0 ELSE 1 END                                      AS work_zone_indicator,
  sb.speed_diff_level
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
JOIN person_stats  AS ps USING (state_number, consecutive_number)
LEFT JOIN vehicle_body AS vb USING (state_number, consecutive_number)
LEFT JOIN speed_bucket AS sb USING (state_number, consecutive_number);