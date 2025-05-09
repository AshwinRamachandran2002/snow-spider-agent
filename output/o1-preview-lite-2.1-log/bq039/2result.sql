SELECT
  p.zone_name AS Pickup_Zone,
  d.zone_name AS Dropoff_Zone,
  TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, MINUTE) AS Trip_Duration_minutes,
  ROUND(
    SAFE_DIVIDE(
      t.trip_distance,
      (TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) / 3600)
    ), 4
  ) AS Driving_Speed_mph,
  ROUND(
    SAFE_MULTIPLY(
      SAFE_DIVIDE(t.tip_amount, t.total_amount),
      100
    ), 4
  ) AS Tip_Rate_Percentage
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
  ON t.pickup_location_id = p.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
  ON t.dropoff_location_id = d.zone_id
WHERE
  DATE(t.pickup_datetime) BETWEEN '2016-07-01' AND '2016-07-07'
  AND t.passenger_count > 5
  AND t.trip_distance >= 10
  AND t.fare_amount > 0
  AND t.total_amount > 0
  AND t.trip_distance IS NOT NULL
  AND t.trip_distance > 0
  AND t.total_amount IS NOT NULL
  AND t.tip_amount IS NOT NULL
  AND t.tip_amount >= 0
  AND t.pickup_datetime IS NOT NULL
  AND t.dropoff_datetime IS NOT NULL
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) > 0
  AND TIMESTAMP_DIFF(t.dropoff_datetime, t.pickup_datetime, SECOND) <= 86400  -- Trip duration within 24 hours
ORDER BY t.total_amount DESC
LIMIT 10;