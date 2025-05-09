-- Top-10 high-fare NYC yellow-taxi rides (Jul 1 – Jul 7 2016)
WITH filtered_trips AS (
  SELECT
    y.total_amount,
    y.tip_amount,
    y.trip_distance,
    TIMESTAMP_DIFF(y.dropoff_datetime, y.pickup_datetime, SECOND) AS trip_duration_seconds,
    pu.zone_name AS pickup_zone,
    do.zone_name AS dropoff_zone
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS pu
         ON y.pickup_location_id  = pu.zone_id
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS do
         ON y.dropoff_location_id = do.zone_id
  WHERE
        -- trip window (inclusive Jul-01 to exclusive Jul-08)
        y.pickup_datetime  >= '2016-07-01'
    AND y.pickup_datetime  <  '2016-07-08'
    AND y.dropoff_datetime >= '2016-07-01'
    AND y.dropoff_datetime <  '2016-07-08'
        -- logical trip
    AND y.dropoff_datetime >  y.pickup_datetime
        -- ride criteria
    AND y.passenger_count  >  5
    AND y.trip_distance    >= 10
        -- no negative money amounts
    AND y.fare_amount   >= 0
    AND y.tip_amount    >= 0
    AND y.mta_tax       >= 0
    AND y.tolls_amount  >= 0
    AND y.total_amount  >= 0
)

SELECT
  pickup_zone,
  dropoff_zone,
  trip_duration_seconds,
  ROUND(trip_distance / (trip_duration_seconds / 3600.0), 2) AS speed_mph,
  ROUND(tip_amount / NULLIF(total_amount,0) * 100, 2)        AS tip_rate_percent,
  total_amount                                               AS total_fare
FROM filtered_trips
ORDER BY total_fare DESC
LIMIT 10;