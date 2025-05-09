-- Highest daily count of electric‑bike rides (>10 min) by “Student Membership”
-- subscribers, excluding trips that start or end at “Mobile Station” or “Repair Shop”.
SELECT 
  MAX(daily_ride_count) AS max_daily_student_electric_rides
FROM (
  SELECT
    DATE(start_time) AS ride_date,
    COUNT(*) AS daily_ride_count
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE
    bike_type = 'electric'
    AND duration_minutes > 10
    AND subscriber_type = 'Student Membership'
    AND start_station_name NOT LIKE '%Mobile Station%'
    AND start_station_name NOT LIKE '%Repair Shop%'
    AND end_station_name   NOT LIKE '%Mobile Station%'
    AND end_station_name   NOT LIKE '%Repair Shop%'
  GROUP BY
    ride_date
);