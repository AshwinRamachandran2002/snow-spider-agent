/* Crash-level labeled data set for 2016 fatal crashes */

WITH person_agg AS (           -- persons & fatal count per crash
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number)            AS person_cnt,
    COUNTIF(injury_severity = 4)             AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),
speed_diff AS (                -- average |travel_speed – speed_limit|
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit))     AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151       -- drop codes 997-999
    AND speed_limit  BETWEEN 5 AND 80        -- drop codes 98-99
  GROUP BY state_number, consecutive_number
),
speed_bins AS (                -- bucket avg speed difference
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN avg_speed_diff < 20 THEN 0
      WHEN avg_speed_diff < 40 THEN 1
      WHEN avg_speed_diff < 60 THEN 2
      WHEN avg_speed_diff < 80 THEN 3
      ELSE 4
    END AS speed_diff_bin
  FROM speed_diff
)

SELECT
  a.state_number,
  a.consecutive_number,
  ANY_VALUE(v.body_type)                        AS body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  IF(COALESCE(a.work_zone,'None') <> 'None', 1, 0) AS work_zone_ind,
  sb.speed_diff_bin,
  CASE WHEN p.fatal_cnt > 1 THEN 1 ELSE 0 END  AS label
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` a
JOIN person_agg  p  USING (state_number, consecutive_number)
LEFT JOIN speed_bins sb USING (state_number, consecutive_number)
LEFT JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016` v
       USING (state_number, consecutive_number)
WHERE p.person_cnt > 1                          -- keep crashes with >1 person
GROUP BY
  a.state_number,
  a.consecutive_number,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  work_zone_ind,
  sb.speed_diff_bin,
  label;