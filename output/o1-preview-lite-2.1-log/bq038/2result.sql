SELECT
  total_trips.start_station_id AS station_id,
  SAFE_DIVIDE(group_rides.group_ride_trips, total_trips.total_trips) AS proportion
FROM (
  SELECT
    start_station_id,
    COUNT(*) AS total_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  GROUP BY start_station_id
) AS total_trips
LEFT JOIN (
  SELECT
    start_station_id,
    COUNT(*) AS group_ride_trips
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE start_station_id = end_station_id AND tripduration <= 120
  GROUP BY start_station_id
) AS group_rides
ON total_trips.start_station_id = group_rides.start_station_id
ORDER BY proportion DESC
LIMIT 10;