SELECT ROUND(AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE)), 4) AS Average_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
  ON CAST(t.pickup_location_id AS STRING) = z.zone_id
WHERE t.passenger_count > 3
  AND t.trip_distance >= 10
  AND t.pickup_datetime >= '2016-02-01'
  AND t.pickup_datetime < '2016-02-08'
  AND z.borough = 'Brooklyn'
  AND t.dropoff_datetime > t.pickup_datetime;