SELECT
  p.zone_name AS pickup_zone,
  d.zone_name AS dropoff_zone,
  TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) AS trip_duration_seconds,
  ROUND(t.trip_distance / NULLIF(TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) / 3600, 0), 4) AS driving_speed_mph,
  ROUND((t.tip_amount / NULLIF(t.total_amount, 0)) * 100, 4) AS tip_rate_percentage
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
    ON t.pickup_location_id = p.zone_id
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
    ON t.dropoff_location_id = d.zone_id
WHERE
  t.pickup_datetime BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
  AND t.dropoff_datetime BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
  AND t.dropoff_datetime > t.pickup_datetime
  AND t.passenger_count > 5
  AND t.trip_distance >= 10
  AND t.fare_amount >= 0
  AND t.tip_amount >= 0
  AND t.tolls_amount >= 0
  AND t.mta_tax >= 0
  AND t.total_amount > 0
  AND t.fare_amount IS NOT NULL
  AND t.tip_amount IS NOT NULL
  AND t.tolls_amount IS NOT NULL
  AND t.mta_tax IS NOT NULL
  AND t.total_amount IS NOT NULL
  AND t.trip_distance IS NOT NULL
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
ORDER BY
  t.total_amount DESC
LIMIT 10;