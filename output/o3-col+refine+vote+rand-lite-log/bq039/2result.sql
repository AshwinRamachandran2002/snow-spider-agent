-- Top-10 highest-fare yellow-cab trips (1–7 Jul 2016) that meet all stated conditions
WITH filtered AS (
  SELECT
      t.pickup_datetime,
      t.dropoff_datetime,
      t.passenger_count,
      t.trip_distance,
      t.fare_amount,
      t.tip_amount,
      t.tolls_amount,
      t.mta_tax,
      t.total_amount,
      t.pickup_location_id,
      t.dropoff_location_id,
      TIMESTAMP_DIFF(t.dropoff_datetime , t.pickup_datetime , SECOND) AS trip_duration_sec
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        -- keep trips whose entire ride occurred between 1 Jul and 7 Jul 2016 23:59:59
        t.pickup_datetime  >= '2016-07-01'
    AND t.pickup_datetime  <  '2016-07-08'
    AND t.dropoff_datetime >= '2016-07-01'
    AND t.dropoff_datetime <  '2016-07-08'
        -- ensure logical chronology
    AND t.dropoff_datetime  > t.pickup_datetime
        -- passenger & distance thresholds
    AND t.passenger_count   > 5
    AND t.trip_distance     >= 10
        -- money fields must be non-negative
    AND t.fare_amount  >= 0
    AND t.tip_amount   >= 0
    AND t.tolls_amount >= 0
    AND t.mta_tax      >= 0
    AND t.total_amount >= 0
)
SELECT
    p.zone_name AS pickup_zone,
    d.zone_name AS dropoff_zone,
    f.trip_duration_sec,
    ROUND(f.trip_distance / (f.trip_duration_sec / 3600.0), 2) AS speed_mph,
    ROUND(100 * f.tip_amount / NULLIF(f.total_amount, 0), 2)   AS tip_rate_pct,
    f.total_amount                                            AS total_fare
FROM filtered AS f
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
  ON f.pickup_location_id = p.zone_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
  ON f.dropoff_location_id = d.zone_id
ORDER BY total_fare DESC
LIMIT 10;