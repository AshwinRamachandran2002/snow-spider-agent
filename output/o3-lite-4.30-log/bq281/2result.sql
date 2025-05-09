SELECT
  CAST(ride_day AS DATE) AS date,
  rides_per_day          AS max_ride_count
FROM (
  SELECT
    DATE(start_time)       AS ride_day,
    COUNT(*)               AS rides_per_day
  FROM `bigquery-public-data.austin_bikeshare.bikeshare_trips`
  WHERE subscriber_type = 'Student Membership'
    AND bike_type       = 'electric'
    AND duration_minutes > 10
    AND COALESCE(LOWER(start_station_name), '') NOT LIKE '%mobile station%'
    AND COALESCE(LOWER(end_station_name),   '') NOT LIKE '%mobile station%'
    AND COALESCE(LOWER(start_station_name), '') NOT LIKE '%repair shop%'
    AND COALESCE(LOWER(end_station_name),   '') NOT LIKE '%repair shop%'
  GROUP BY ride_day
  ORDER BY rides_per_day DESC, ride_day
  LIMIT 1
);