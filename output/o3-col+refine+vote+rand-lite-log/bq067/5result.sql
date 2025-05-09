-- Build a labelled dataset of 2016 fatal-crashes that involve >1 person
-- label = 1 if >1 person in the crash has injury_severity = 4, else 0
WITH speed_feature AS (
  -- average |travel_speed – speed_limit| per crash,
  -- bucketed into 0-4 (20-mph increments)
  SELECT
    state_number,
    consecutive_number,
    CASE
      WHEN AVG(ABS(travel_speed - speed_limit)) < 20 THEN 0
      WHEN AVG(ABS(travel_speed - speed_limit)) < 40 THEN 1
      WHEN AVG(ABS(travel_speed - speed_limit)) < 60 THEN 2
      WHEN AVG(ABS(travel_speed - speed_limit)) < 80 THEN 3
      ELSE 4
    END AS speed_diff_level
  FROM `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE travel_speed BETWEEN 0 AND 151        -- drop 997/998/999 codes
    AND speed_limit  BETWEEN 5 AND 80         -- drop 0/98/99 codes
  GROUP BY state_number, consecutive_number
)

SELECT
  a.state_number,
  a.consecutive_number,
  ANY_VALUE(v.body_type)              AS body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  CASE
      WHEN CAST(a.work_zone AS STRING) = 'None'
        OR CAST(a.work_zone AS STRING) = '0'
        OR a.work_zone IS NULL          THEN 0
      ELSE 1
  END                                   AS work_zone_ind,
  s.speed_diff_level,
  CASE
      WHEN SUM(CASE WHEN p.injury_severity = 4 THEN 1 ELSE 0 END) > 1
           THEN 1
      ELSE 0
  END                                   AS label
FROM `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` a
JOIN `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`   p
  ON a.state_number = p.state_number
 AND a.consecutive_number = p.consecutive_number
JOIN `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`  v
  ON a.state_number = v.state_number
 AND a.consecutive_number = v.consecutive_number
JOIN speed_feature s
  ON a.state_number = s.state_number
 AND a.consecutive_number = s.consecutive_number
GROUP BY
  a.state_number,
  a.consecutive_number,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  work_zone_ind,
  s.speed_diff_level
HAVING COUNT(DISTINCT p.person_number) > 1;