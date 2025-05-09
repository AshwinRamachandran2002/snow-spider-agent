-- Top-10 most expensive large-party yellow-cab trips between 1–7 July 2016
WITH filtered AS (
  SELECT
    t.pickup_datetime,
    t.dropoff_datetime,
    t.passenger_count,
    CAST(t.trip_distance AS FLOAT64)       AS trip_miles,
    CAST(t.fare_amount   AS FLOAT64)       AS fare_amount,
    CAST(t.tip_amount    AS FLOAT64)       AS tip_amount,
    CAST(t.tolls_amount  AS FLOAT64)       AS tolls_amount,
    CAST(t.mta_tax       AS FLOAT64)       AS mta_tax,
    CAST(t.total_amount  AS FLOAT64)       AS total_amount,
    t.pickup_location_id,
    t.dropoff_location_id,
    TIMESTAMP_DIFF(t.dropoff_datetime,
                   t.pickup_datetime,
                   SECOND)                 AS trip_seconds
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        -- keep only rides whose entire span is within 1–7 Jul 2016
        t.pickup_datetime  BETWEEN '2016-07-01' AND '2016-07-08'
    AND t.dropoff_datetime BETWEEN '2016-07-01' AND '2016-07-08'
        -- logical sanity checks
    AND t.dropoff_datetime > t.pickup_datetime
        -- problem-specific filters
    AND t.passenger_count  > 5
    AND CAST(t.trip_distance AS FLOAT64) >= 10
        -- exclude any negative monetary values
    AND t.fare_amount  >= 0
    AND t.tip_amount   >= 0
    AND t.tolls_amount >= 0
    AND t.mta_tax      >= 0
    AND t.total_amount >= 0
)

SELECT
  p.zone_name                                              AS pickup_zone,
  d.zone_name                                              AS dropoff_zone,
  f.trip_seconds,
  ROUND( f.trip_miles / (f.trip_seconds/3600), 2 )         AS speed_mph,
  ROUND( SAFE_DIVIDE(f.tip_amount, f.total_amount) * 100 , 2 ) AS tip_pct,
  f.total_amount
FROM filtered AS f
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
  ON p.zone_id = f.pickup_location_id
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
  ON d.zone_id = f.dropoff_location_id
ORDER BY f.total_amount DESC
LIMIT 10;