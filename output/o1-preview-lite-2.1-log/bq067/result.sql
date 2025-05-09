WITH vehicle_stats AS (
  SELECT
    state_number,
    consecutive_number,
    body_type AS Vehicle_type,
    ABS(travel_speed - speed_limit) AS speed_diff
  FROM
    `bigquery-public-data.nhtsa_traffic_fatalities.vehicle_2016`
  WHERE
    travel_speed NOT IN (997, 998, 999)
    AND speed_limit NOT IN (98, 99)
    AND travel_speed IS NOT NULL
    AND speed_limit IS NOT NULL
),
vehicle_agg AS (
  SELECT
    state_number,
    consecutive_number,
    AVG(speed_diff) AS avg_speed_diff
  FROM
    vehicle_stats
  GROUP BY
    state_number,
    consecutive_number
),
vehicle_type_counts AS (
  SELECT
    state_number,
    consecutive_number,
    Vehicle_type,
    COUNT(*) AS cnt
  FROM
    vehicle_stats
  GROUP BY
    state_number,
    consecutive_number,
    Vehicle_type
),
vehicle_type_mode AS (
  SELECT
    state_number,
    consecutive_number,
    Vehicle_type
  FROM (
    SELECT
      state_number,
      consecutive_number,
      Vehicle_type,
      ROW_NUMBER() OVER (PARTITION BY state_number, consecutive_number ORDER BY cnt DESC) AS rn
    FROM
      vehicle_type_counts
  )
  WHERE rn = 1
),
vehicle_data AS (
  SELECT
    agg.state_number,
    agg.consecutive_number,
    mode.Vehicle_type,
    ROUND(agg.avg_speed_diff, 4) AS avg_speed_diff
  FROM
    vehicle_agg agg
  LEFT JOIN
    vehicle_type_mode mode
  ON
    agg.state_number = mode.state_number
    AND agg.consecutive_number = mode.consecutive_number
)
SELECT
  IF(acc.number_of_fatalities > 1, 1, 0) AS Label,
  acc.state_number AS State,
  veh.Vehicle_type,
  acc.number_of_drunk_drivers AS Number_of_drunk_drivers,
  acc.day_of_week AS Day_of_week,
  acc.hour_of_crash AS Hour_of_day,
  IF(acc.work_zone IS NOT NULL AND acc.work_zone != 'None', 1, 0) AS Work_zone,
  CASE
    WHEN veh.avg_speed_diff >= 0 AND veh.avg_speed_diff < 20 THEN 0
    WHEN veh.avg_speed_diff >= 20 AND veh.avg_speed_diff < 40 THEN 1
    WHEN veh.avg_speed_diff >= 40 AND veh.avg_speed_diff < 60 THEN 2
    WHEN veh.avg_speed_diff >= 60 AND veh.avg_speed_diff < 80 THEN 3
    WHEN veh.avg_speed_diff >= 80 THEN 4
    ELSE NULL
  END AS Speed_diff_level
FROM
  `bigquery-public-data.nhtsa_traffic_fatalities.accident_2016` acc
LEFT JOIN
  vehicle_data veh
ON
  acc.state_number = veh.state_number
  AND acc.consecutive_number = veh.consecutive_number
WHERE
  (acc.number_of_persons_in_motor_vehicles_in_transport_mvit + acc.number_of_persons_not_in_motor_vehicles_in_transport_mvit) >= 2;