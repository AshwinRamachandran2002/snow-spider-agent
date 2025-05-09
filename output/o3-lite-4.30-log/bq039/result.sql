SELECT
  zpu.zone_name AS pickup_zone,
  zdo.zone_name AS dropoff_zone,
  TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND) AS trip_duration_seconds,
  ROUND(y.trip_distance * 3600 /
        TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND), 4) AS driving_speed_mph,
  ROUND(SAFE_DIVIDE(y.tip_amount, y.total_amount) * 100, 4) AS tip_rate_percent
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS zpu
  ON zpu.zone_id = y.pickup_location_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS zdo
  ON zdo.zone_id = y.dropoff_location_id
WHERE y.pickup_datetime >= '2016-07-01 00:00:00'
  AND y.pickup_datetime <  '2016-07-08 00:00:00'
  AND y.dropoff_datetime >= '2016-07-01 00:00:00'
  AND y.dropoff_datetime <  '2016-07-08 00:00:00'
  AND y.dropoff_datetime  >  y.pickup_datetime
  AND y.passenger_count   >  5
  AND y.trip_distance     >= 10
  AND y.fare_amount       >= 0
  AND y.tip_amount        >= 0
  AND y.tolls_amount      >= 0
  AND y.mta_tax           >= 0
  AND y.total_amount      >= 0
ORDER BY y.total_amount DESC, y.pickup_datetime
LIMIT 10;