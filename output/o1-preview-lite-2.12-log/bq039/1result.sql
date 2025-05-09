SELECT
  pz.zone_name AS Pickup_Zone,
  dz.zone_name AS Dropoff_Zone,
  TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) AS Trip_Duration_Seconds,
  SAFE_DIVIDE(t.trip_distance, TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) / 3600) AS Driving_Speed_MPH,
  (t.tip_amount / t.total_amount) * 100 AS Tip_Rate_Percentage
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
LEFT JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS pz
    ON t.pickup_location_id = pz.zone_id
LEFT JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS dz
    ON t.dropoff_location_id = dz.zone_id
WHERE
  t.pickup_datetime BETWEEN '2016-07-01' AND '2016-07-07'
  AND t.dropoff_datetime BETWEEN '2016-07-01' AND '2016-07-07'
  AND t.dropoff_datetime > t.pickup_datetime
  AND t.passenger_count > 5
  AND t.trip_distance >= 10
  AND t.fare_amount >= 0
  AND t.tip_amount >= 0
  AND t.tolls_amount >= 0
  AND t.mta_tax >= 0
  AND t.total_amount >= 0
  AND t.fare_amount IS NOT NULL
  AND t.tip_amount IS NOT NULL
  AND t.tolls_amount IS NOT NULL
  AND t.mta_tax IS NOT NULL
  AND t.total_amount IS NOT NULL
  AND t.trip_distance IS NOT NULL
  AND t.pickup_datetime IS NOT NULL
  AND t.dropoff_datetime IS NOT NULL
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
ORDER BY
  t.total_amount DESC
LIMIT
  10;