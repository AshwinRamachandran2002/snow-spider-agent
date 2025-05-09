SELECT DATE(start_time) AS Date, COUNT(*) AS Number_of_Rides
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
WHERE LOWER(bike_type) = 'electric'
  AND duration_minutes > 10
  AND LOWER(subscriber_type) LIKE '%student%'
  AND LOWER(start_station_name) NOT LIKE '%mobile station%'
  AND LOWER(start_station_name) NOT LIKE '%repair shop%'
  AND LOWER(end_station_name) NOT LIKE '%mobile station%'
  AND LOWER(end_station_name) NOT LIKE '%repair shop%'
GROUP BY Date
ORDER BY Number_of_Rides DESC
LIMIT 1;