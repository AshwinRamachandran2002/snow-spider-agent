-- Task: List the number of electric bike rides lasting more than 10 minutes taken by subscribers with 'Student Membership' per day, excluding rides starting or ending at 'Mobile Station' or 'Repair Shop'.
SELECT
  DATE(start_time) AS ride_date,
  COUNT(1) AS num_rides
FROM
  `bigquery-public-data.austin_bikeshare.bikeshare_trips`
WHERE
  start_station_name NOT IN ('Mobile Station', 'Repair Shop')
  AND end_station_name NOT IN ('Mobile Station', 'Repair Shop')
  AND subscriber_type = 'Student Membership'
  AND bike_type = 'electric'
  AND duration_minutes > 10
GROUP BY
  DATE(start_time)
ORDER BY
  num_rides DESC
LIMIT 100