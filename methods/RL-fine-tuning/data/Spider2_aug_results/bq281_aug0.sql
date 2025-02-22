-- Task: Determine the highest number of electric bike rides lasting over 10 minutes taken by 'Student Membership' subscribers in a single day, excluding rides that start or end at 'Mobile Station' or 'Repair Shop'. Return the maximum daily count of such rides.
SELECT
  COUNT(1) AS num_rides
FROM
  `bigquery-public-data.austin_bikeshare.bikeshare_trips` 
WHERE 
  start_station_name NOT IN ('Mobile Station', 'Repair Shop')
  AND
  end_station_name NOT IN ('Mobile Station', 'Repair Shop')
  AND 
  subscriber_type = 'Student Membership'
  AND
  bike_type = 'electric'
  AND
  duration_minutes > 10
GROUP BY 
    EXTRACT(YEAR FROM start_time), 
    EXTRACT(MONTH FROM start_time), 
    EXTRACT(DAY FROM start_time)
ORDER BY num_rides DESC
LIMIT 1