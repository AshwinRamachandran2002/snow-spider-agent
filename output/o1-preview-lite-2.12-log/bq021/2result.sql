WITH citibike_top_routes AS (
  SELECT
    ROUND(start_station_latitude, 3) AS start_lat,
    ROUND(start_station_longitude, 3) AS start_lon,
    ROUND(end_station_latitude, 3) AS end_lat,
    ROUND(end_station_longitude, 3) AS end_lon,
    start_station_name,
    AVG(tripduration) AS avg_bike_duration,
    COUNT(*) AS bike_trip_count
  FROM `bigquery-public-data.new_york.citibike_trips`
  WHERE EXTRACT(YEAR FROM starttime) = 2016
  GROUP BY start_lat, start_lon, end_lat, end_lon, start_station_name
  ORDER BY bike_trip_count DESC
  LIMIT 20
),
taxi_routes AS (
  SELECT
    ROUND(pickup_latitude, 3) AS pickup_lat,
    ROUND(pickup_longitude, 3) AS pickup_lon,
    ROUND(dropoff_latitude, 3) AS dropoff_lat,
    ROUND(dropoff_longitude, 3) AS dropoff_lon,
    AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)) AS avg_taxi_duration,
    COUNT(*) AS taxi_trip_count
  FROM `bigquery-public-data.new_york.tlc_yellow_trips_2016`
  WHERE
    pickup_datetime >= '2016-01-01' AND pickup_datetime < '2017-01-01' AND
    pickup_latitude IS NOT NULL AND
    pickup_longitude IS NOT NULL AND
    dropoff_latitude IS NOT NULL AND
    dropoff_longitude IS NOT NULL AND
    ABS(pickup_latitude) > 0 AND ABS(pickup_longitude) > 0 AND
    ABS(dropoff_latitude) > 0 AND ABS(dropoff_longitude) > 0
  GROUP BY pickup_lat, pickup_lon, dropoff_lat, dropoff_lon
)
SELECT
  bike.start_station_name
FROM citibike_top_routes AS bike
JOIN taxi_routes AS taxi
ON
  bike.start_lat = taxi.pickup_lat AND
  bike.start_lon = taxi.pickup_lon AND
  bike.end_lat = taxi.dropoff_lat AND
  bike.end_lon = taxi.dropoff_lon
WHERE bike.avg_bike_duration < taxi.avg_taxi_duration
ORDER BY bike.avg_bike_duration DESC
LIMIT 1;