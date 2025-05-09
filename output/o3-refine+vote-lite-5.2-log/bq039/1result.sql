-- Top 10 high‑fare* long NYC taxi trips (7/1/2016‑7/7/2016)
WITH yellow AS (
  SELECT
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    mta_tax,
    tip_amount,
    tolls_amount,
    total_amount,
    CAST(pickup_location_id  AS STRING) AS pu_zone_id,
    CAST(dropoff_location_id AS STRING) AS do_zone_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE pickup_datetime  BETWEEN TIMESTAMP('2016-07-01') AND TIMESTAMP('2016-07-07 23:59:59')
    AND dropoff_datetime BETWEEN TIMESTAMP('2016-07-01') AND TIMESTAMP('2016-07-07 23:59:59')
),
green AS (
  SELECT
    pickup_datetime,
    dropoff_datetime,
    passenger_count,
    trip_distance,
    fare_amount,
    mta_tax,
    tip_amount,
    tolls_amount,
    total_amount,
    CAST(pickup_location_id  AS STRING) AS pu_zone_id,
    CAST(dropoff_location_id AS STRING) AS do_zone_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
  WHERE pickup_datetime  BETWEEN TIMESTAMP('2016-07-01') AND TIMESTAMP('2016-07-07 23:59:59')
    AND dropoff_datetime BETWEEN TIMESTAMP('2016-07-01') AND TIMESTAMP('2016-07-07 23:59:59')
),
trips AS (
  SELECT * FROM yellow
  UNION ALL
  SELECT * FROM green
),
filtered AS (
  SELECT
    t.*,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS duration_sec
  FROM trips t
  WHERE passenger_count > 5                          -- more than 5 riders
    AND trip_distance >= 10                          -- at least 10 miles
    AND fare_amount   >= 0
    AND mta_tax       >= 0
    AND tip_amount    >= 0
    AND tolls_amount  >= 0
    AND total_amount  >= 0                           -- no negative money values
    AND dropoff_datetime > pickup_datetime           -- drop‑off strictly after pick‑up
)
SELECT
  COALESCE(pu.zone_name,'Unknown')  AS pickup_zone,
  COALESCE(do.zone_name,'Unknown')  AS dropoff_zone,
  duration_sec,
  ROUND(SAFE_DIVIDE(trip_distance, duration_sec/3600.0), 2) AS speed_mph,
  ROUND(SAFE_DIVIDE(tip_amount, NULLIF(total_amount,0))*100, 2) AS tip_rate_pct
FROM filtered f
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` pu
       ON f.pu_zone_id = pu.zone_id
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` do
       ON f.do_zone_id = do.zone_id
ORDER BY total_amount DESC
LIMIT 10;