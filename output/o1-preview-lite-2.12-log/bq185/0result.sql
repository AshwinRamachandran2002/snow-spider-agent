SELECT
  AVG(TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE)) AS average_trip_duration_minutes
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS zp
    ON t.pickup_location_id = zp.zone_id
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS zd
    ON t.dropoff_location_id = zd.zone_id
WHERE
  t.pickup_datetime BETWEEN '2016-02-01' AND '2016-02-07'
  AND t.passenger_count > 3
  AND t.trip_distance >= 10
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
  AND LOWER(zp.borough) = 'brooklyn'
  AND LOWER(zd.borough) = 'brooklyn';