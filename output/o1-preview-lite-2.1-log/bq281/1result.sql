SELECT DATE(start_time) AS Date, COUNT(*) AS Number_of_Rides
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
WHERE bike_type = 'electric'
  AND duration_minutes > 10
  AND subscriber_type = 'Student Membership'
  AND start_station_name NOT LIKE '%Repair%'
  AND end_station_name NOT LIKE '%Repair%'
  AND start_station_name NOT LIKE '%Mobile%'
  AND end_station_name NOT LIKE '%Mobile%'
  AND DATE(start_time) <= '2023-09-30'
GROUP BY Date
ORDER BY Number_of_Rides DESC
LIMIT 1;