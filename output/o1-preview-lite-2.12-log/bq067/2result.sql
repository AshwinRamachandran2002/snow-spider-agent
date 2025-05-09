WITH person_counts AS (
  SELECT
    consecutive_number,
    COUNT(DISTINCT person_number) AS num_persons,
    SUM(CASE WHEN injury_severity = 4 THEN 1 ELSE 0 END) AS num_fatalities
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.person_2016`
  GROUP BY
    consecutive_number
  HAVING
    COUNT(DISTINCT person_number) > 1
),
person_labels AS (
  SELECT
    consecutive_number,
    CASE WHEN num_fatalities > 1 THEN 1 ELSE 0 END AS label
  FROM
    person_counts
),
accident_data AS (
  SELECT
    consecutive_number,
    state_number,
    day_of_week,
    hour_of_crash,
    number_of_drunk_drivers,
    CASE WHEN LOWER(IFNULL(work_zone, 'none')) = 'none' THEN 0 ELSE 1 END AS work_zone
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016`
),
vehicle_data AS (
  SELECT
    consecutive_number,
    vehicle_number,
    body_type,
    travel_speed
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE
    travel_speed <= 151 AND travel_speed NOT IN (997, 998, 999)
),
vehicle_body_type AS (
  SELECT
    consecutive_number,
    ANY_VALUE(body_type) AS body_type
  FROM
    vehicle_data
  GROUP BY
    consecutive_number
)
SELECT
  a.state_number,
  v.body_type,
  a.number_of_drunk_drivers,
  a.day_of_week,
  a.hour_of_crash,
  a.work_zone,
  p.label
FROM
  person_labels p
JOIN
  accident_data a
ON
  p.consecutive_number = a.consecutive_number
LEFT JOIN
  vehicle_body_type v
ON
  p.consecutive_number = v.consecutive_number;