SELECT DATE(`start_time`) AS `Date`, COUNT(`trip_id`) AS `Number_of_Rides`
FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
WHERE LOWER(`subscriber_type`) = 'student membership'
  AND LOWER(`bike_type`) = 'electric'
  AND `duration_minutes` > 10
  AND LOWER(`start_station_name`) NOT LIKE '%mobile%' 
  AND LOWER(`start_station_name`) NOT LIKE '%repair%'
  AND LOWER(`end_station_name`) NOT LIKE '%mobile%' 
  AND LOWER(`end_station_name`) NOT LIKE '%repair%'
GROUP BY `Date`
ORDER BY `Number_of_Rides` DESC
LIMIT 1;