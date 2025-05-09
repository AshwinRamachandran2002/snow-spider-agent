SELECT
  p.zone_name AS pickup_zone,
  d.zone_name AS dropoff_zone,
  TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND)                         AS trip_duration_seconds,
  ROUND(
        CAST(y.trip_distance AS FLOAT64) /
        (TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND) / 3600.0), 
        4)                                                                              AS driving_speed_mph,
  ROUND(100 * y.tip_amount / NULLIF(y.total_amount, 0), 4)                              AS tip_rate_percent
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS p
  ON y.pickup_location_id = p.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS d
  ON y.dropoff_location_id = d.zone_id
WHERE y.pickup_datetime  BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
  AND y.dropoff_datetime BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
  AND y.dropoff_datetime  > y.pickup_datetime                 -- ensure positive duration
  AND y.passenger_count   > 5
  AND y.trip_distance     >= 10
  AND y.fare_amount       >= 0
  AND y.tip_amount        >= 0
  AND y.tolls_amount      >= 0
  AND y.mta_tax           >= 0
  AND y.total_amount      >= 0
ORDER BY y.total_amount DESC, y.pickup_datetime
LIMIT 10;