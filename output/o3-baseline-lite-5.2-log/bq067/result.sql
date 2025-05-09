/* Labeled dataset of 2016 fatal crashes (BigQuery) */
WITH person_stats AS (        -- 1. crashes with >1 person + fatal count
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)                                AS persons_in_crash,
    SUM(CASE WHEN injury_severity = 4 THEN 1 END)               AS fatals_in_crash
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
  HAVING COUNT(DISTINCT person_number) > 1
),
speed_diff AS (               -- 2. avg |travel_speed‑speed_limit| per crash
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_abs_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE
        travel_speed NOT IN (997, 998, 999)
    AND travel_speed <= 151
    AND speed_limit  NOT IN (98, 99)
    AND speed_limit  <= 80
  GROUP BY state_number, consecutive_number
),
speed_bins AS (               -- 3. bucket the average speed difference
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_abs_speed_diff IS NULL THEN NULL
      WHEN avg_abs_speed_diff < 20  THEN 0
      WHEN avg_abs_speed_diff < 40  THEN 1
      WHEN avg_abs_speed_diff < 60  THEN 2
      WHEN avg_abs_speed_diff < 80  THEN 3
      ELSE                              4
    END AS speed_diff_level
  FROM speed_diff
),
vehicle_body AS (             -- 4. body type of first in‑transport vehicle
  SELECT
    state_number,
    consecutive_number,
    ANY_VALUE(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE vehicle_number = 1
  GROUP BY state_number, consecutive_number
)
SELECT
  a.state_number,                             -- predictors
  vb.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  CASE                                             -- work‑zone indicator
      WHEN SAFE_CAST(a.work_zone AS INT64) = 0 THEN 0
      ELSE 1
  END AS work_zone_ind,
  sb.speed_diff_level,                            -- engineered feature
  CASE WHEN ps.fatals_in_crash > 1 THEN 1 ELSE 0 END AS label   -- target
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
JOIN person_stats  AS ps ON a.state_number = ps.state_number
                        AND a.consecutive_number = ps.consecutive_number
LEFT JOIN speed_bins   AS sb ON a.state_number = sb.state_number
                             AND a.consecutive_number = sb.consecutive_number
LEFT JOIN vehicle_body AS vb ON a.state_number = vb.state_number
                             AND a.consecutive_number = vb.consecutive_number;