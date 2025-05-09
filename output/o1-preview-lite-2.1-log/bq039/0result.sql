SELECT
  pz.zone_name AS Pickup_Zone,
  dz.zone_name AS Dropoff_Zone,
  TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) AS Trip_Duration_minutes,
  ROUND(t.trip_distance / (TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) / 3600), 4) AS Driving_Speed_mph,
  ROUND((t.tip_amount / t.fare_amount) * 100, 4) AS Tip_Rate_Percentage
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS pz
    ON t.pickup_location_id = pz.zone_id
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS dz
    ON t.dropoff_location_id = dz.zone_id
WHERE
  t.pickup_datetime >= '2016-07-01' AND t.pickup_datetime < '2016-07-08'
  AND t.passenger_count > 5
  AND t.trip_distance >= 10
  AND t.total_amount > 0
  AND t.fare_amount > 0
  AND t.tip_amount >= 0
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
  AND t.trip_distance > 0
ORDER BY
  t.total_amount DESC
LIMIT 10;