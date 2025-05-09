WITH person_stats AS (
  SELECT
    state_number,
    consecutive_number,
    COUNT(DISTINCT person_number) AS person_cnt,
    COUNTIF(injury_severity = 4)  AS fatal_cnt
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY state_number, consecutive_number
),
speed_stats AS (
  SELECT
    state_number,
    consecutive_number,
    AVG(ABS(travel_speed - speed_limit)) AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151
    AND travel_speed NOT IN (997, 998, 999)
    AND speed_limit BETWEEN 5 AND 80
    AND speed_limit NOT IN (98, 99)
  GROUP BY state_number, consecutive_number
),
body_type_per_accident AS (
  SELECT
    state_number,
    consecutive_number,
    ANY_VALUE(body_type) AS body_type
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  GROUP BY state_number, consecutive_number
)
SELECT
  CASE WHEN ps.fatal_cnt > 1 THEN 1 ELSE 0 END                 AS label,
  a.state_number                                               AS state_number,
  bt.body_type                                                 AS body_type,
  a.number_of_drunk_drivers                                    AS number_of_drunk_drivers,
  a.day_of_week                                                AS day_of_week,
  a.hour_of_crash                                              AS hour_of_crash,
  CASE WHEN CAST(a.work_zone AS STRING) = '0' THEN 0 ELSE 1 END AS work_zone_indicator,
  CASE
    WHEN ss.avg_speed_diff < 20 THEN 0
    WHEN ss.avg_speed_diff < 40 THEN 1
    WHEN ss.avg_speed_diff < 60 THEN 2
    WHEN ss.avg_speed_diff < 80 THEN 3
    ELSE 4
  END                                                         AS speed_diff_level
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` AS a
JOIN person_stats           AS ps ON ps.state_number = a.state_number
                                 AND ps.consecutive_number = a.consecutive_number
JOIN speed_stats            AS ss ON ss.state_number = a.state_number
                                 AND ss.consecutive_number = a.consecutive_number
JOIN body_type_per_accident AS bt ON bt.state_number = a.state_number
                                 AND bt.consecutive_number = a.consecutive_number
WHERE ps.person_cnt > 1;