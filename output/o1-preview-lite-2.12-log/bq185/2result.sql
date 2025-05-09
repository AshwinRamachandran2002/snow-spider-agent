SELECT
  AVG(TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE)) AS average_trip_duration_minutes
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z_pickup
ON
  t.pickup_location_id = z_pickup.zone_id
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z_dropoff
ON
  t.dropoff_location_id = z_dropoff.zone_id
WHERE
  DATE(t.pickup_datetime) BETWEEN '2016-02-01' AND '2016-02-07'
  AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, MINUTE) > 0
  AND t.passenger_count > 3
  AND t.trip_distance >= 10
  AND LOWER(z_pickup.borough) = 'brooklyn'
  AND LOWER(z_dropoff.borough) = 'brooklyn';