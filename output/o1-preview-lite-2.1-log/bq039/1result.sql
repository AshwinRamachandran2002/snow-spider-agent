SELECT
  pz.zone_name AS Pickup_Zone,
  dz.zone_name AS Dropoff_Zone,
  TIMESTAMP_DIFF(trip.dropoff_datetime, trip.pickup_datetime, MINUTE) AS Trip_Duration_minutes,
  ROUND(trip.trip_distance / (TIMESTAMP_DIFF(trip.dropoff_datetime, trip.pickup_datetime, SECOND) / 3600), 4) AS Driving_Speed_mph,
  ROUND((trip.tip_amount / trip.fare_amount) * 100, 4) AS Tip_Rate_Percentage
FROM
  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS trip
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS pz
    ON trip.pickup_location_id = pz.zone_id
JOIN
  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS dz
    ON trip.dropoff_location_id = dz.zone_id
WHERE
  trip.pickup_datetime BETWEEN '2016-07-01' AND '2016-07-07 23:59:59'
  AND trip.passenger_count > 5
  AND trip.trip_distance >= 10
  AND trip.fare_amount > 0
  AND trip.tip_amount IS NOT NULL
  AND trip.pickup_datetime IS NOT NULL
  AND trip.dropoff_datetime IS NOT NULL
  AND TIMESTAMP_DIFF(trip.dropoff_datetime, trip.pickup_datetime, SECOND) > 0
ORDER BY
  trip.total_amount DESC
LIMIT 10;