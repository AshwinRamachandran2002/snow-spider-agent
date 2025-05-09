WITH accidents_with_more_than_one_person AS (
  SELECT consecutive_number
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY consecutive_number
  HAVING COUNT(DISTINCT person_number) > 1
),
accidents_with_label AS (
  SELECT p.consecutive_number,
         SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END) AS num_fatalities
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.person_2016` p
  WHERE p.consecutive_number IN (SELECT consecutive_number FROM accidents_with_more_than_one_person)
  GROUP BY p.consecutive_number
),
accidents_and_labels AS (
  SELECT consecutive_number,
         CASE WHEN num_fatalities > 1 THEN 1 ELSE 0 END AS label
  FROM accidents_with_label
),
average_speed_difference AS (
  SELECT v.consecutive_number,
         AVG(ABS(v.travel_speed - v.speed_limit)) AS avg_speed_diff
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016` v
  WHERE v.consecutive_number IN (SELECT consecutive_number FROM accidents_with_more_than_one_person)
    AND v.travel_speed NOT IN (997, 998, 999) AND v.travel_speed < 151
    AND v.speed_limit NOT IN (98, 99) AND v.speed_limit < 80
  GROUP BY v.consecutive_number
),
speed_difference_levels AS (
  SELECT consecutive_number,
         CASE
             WHEN avg_speed_diff >= 0 AND avg_speed_diff < 20 THEN 0
             WHEN avg_speed_diff >= 20 AND avg_speed_diff < 40 THEN 1
             WHEN avg_speed_diff >= 40 AND avg_speed_diff < 60 THEN 2
             WHEN avg_speed_diff >= 60 AND avg_speed_diff < 80 THEN 3
             WHEN avg_speed_diff >= 80 THEN 4
         END AS speed_difference_level
  FROM average_speed_difference
),
vehicle_body_types AS (
  SELECT v.consecutive_number,
         v.body_type
  FROM (
    SELECT v.*,
           ROW_NUMBER() OVER (PARTITION BY v.consecutive_number ORDER BY v.vehicle_number) AS rn
    FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016` v
    WHERE v.consecutive_number IN (SELECT consecutive_number FROM accidents_with_more_than_one_person)
  ) v
  WHERE v.rn = 1
),
accident_info AS (
  SELECT a.consecutive_number,
         a.state_number,
         a.number_of_drunk_drivers,
         a.day_of_week,
         a.hour_of_crash,
         CASE WHEN LOWER(IFNULL(a.work_zone, 'none')) != 'none' THEN 1 ELSE 0 END AS work_zone
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` a
  WHERE a.consecutive_number IN (SELECT consecutive_number FROM accidents_with_more_than_one_person)
)
SELECT ai.state_number,
       CAST(vbt.body_type AS STRING) AS body_type,
       ai.number_of_drunk_drivers,
       ai.day_of_week,
       ai.hour_of_crash,
       ai.work_zone,
       sdl.speed_difference_level,
       aal.label
FROM accidents_and_labels aal
JOIN accident_info ai ON aal.consecutive_number = ai.consecutive_number
JOIN vehicle_body_types vbt ON aal.consecutive_number = vbt.consecutive_number
LEFT JOIN speed_difference_levels sdl ON aal.consecutive_number = sdl.consecutive_number