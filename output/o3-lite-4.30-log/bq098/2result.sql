SELECT
  tz.borough AS pickup_borough,
  ROUND(
    100 * COUNTIF(y.total_amount = 0 OR (y.total_amount > 0 AND y.tip_amount = 0)) / COUNT(*),
    4
  ) AS percentage_no_tip
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`         AS tz
  ON y.pickup_location_id = tz.zone_id
WHERE DATE(y.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
  AND DATE(y.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
  AND y.dropoff_datetime > y.pickup_datetime
  AND y.passenger_count > 0
  AND y.trip_distance  >= 0
  AND y.tip_amount     >= 0
  AND y.tolls_amount   >= 0
  AND y.mta_tax        >= 0
  AND y.fare_amount    >= 0
  AND y.total_amount   >= 0
GROUP BY pickup_borough
ORDER BY pickup_borough;