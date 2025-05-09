SELECT ROUND(AVG(TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE)), 4) AS average_trip_duration_minutes
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
  ON t.pickup_location_id = z.zone_id
WHERE z.borough = 'Brooklyn'
  AND t.passenger_count > 3
  AND t.trip_distance >= 10
  AND t.pickup_datetime BETWEEN '2016-02-01' AND '2016-02-07 23:59:59'
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) BETWEEN 1 AND 300;