WITH trips AS (
  --  Yellow taxi trips
  SELECT
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    dropoff_location_id,
    passenger_count,
    SAFE_CAST(trip_distance AS FLOAT64)     AS trip_distance,
    SAFE_CAST(fare_amount  AS FLOAT64)      AS fare_amount,
    SAFE_CAST(tip_amount   AS FLOAT64)      AS tip_amount,
    SAFE_CAST(tolls_amount AS FLOAT64)      AS tolls_amount,
    SAFE_CAST(mta_tax      AS FLOAT64)      AS mta_tax,
    SAFE_CAST(total_amount AS FLOAT64)      AS total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  
  UNION ALL
  
  --  Green taxi trips
  SELECT
    pickup_datetime,
    dropoff_datetime,
    pickup_location_id,
    dropoff_location_id,
    passenger_count,
    SAFE_CAST(trip_distance AS FLOAT64)     AS trip_distance,
    SAFE_CAST(fare_amount  AS FLOAT64)      AS fare_amount,
    SAFE_CAST(tip_amount   AS FLOAT64)      AS tip_amount,
    SAFE_CAST(tolls_amount AS FLOAT64)      AS tolls_amount,
    SAFE_CAST(mta_tax      AS FLOAT64)      AS mta_tax,
    SAFE_CAST(total_amount AS FLOAT64)      AS total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
),
filtered AS (
  SELECT *
  FROM trips
  WHERE
        pickup_datetime  >= TIMESTAMP('2016-07-01 00:00:00')
    AND pickup_datetime  <  TIMESTAMP('2016-07-08 00:00:00')
    AND dropoff_datetime >= TIMESTAMP('2016-07-01 00:00:00')
    AND dropoff_datetime <  TIMESTAMP('2016-07-08 00:00:00')
    AND dropoff_datetime  >  pickup_datetime                -- valid chronology
    AND passenger_count   >  5                              -- >5 passengers
    AND trip_distance     >= 10                             -- ≥10 miles
    AND fare_amount       >= 0                              -- all non‑negative amounts
    AND tip_amount        >= 0
    AND tolls_amount      >= 0
    AND mta_tax           >= 0
    AND total_amount      >= 0
),
enriched AS (
  SELECT
    zpu.zone_name                                       AS pickup_zone,
    zdo.zone_name                                       AS dropoff_zone,
    TIMESTAMP_DIFF(f.dropoff_datetime,
                   f.pickup_datetime,
                   SECOND)                              AS duration_seconds,
    f.trip_distance*3600
      / NULLIF(TIMESTAMP_DIFF(f.dropoff_datetime,
                              f.pickup_datetime,
                              SECOND),0)                AS speed_mph,
    CASE WHEN f.total_amount > 0
         THEN f.tip_amount*100 / f.total_amount
    END                                                 AS tip_rate_pct,
    f.total_amount
  FROM filtered AS f
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` zpu
         ON zpu.zone_id = f.pickup_location_id
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` zdo
         ON zdo.zone_id = f.dropoff_location_id
)
SELECT
  pickup_zone,
  dropoff_zone,
  duration_seconds,
  ROUND(speed_mph,   4) AS speed_mph,
  ROUND(tip_rate_pct,4) AS tip_rate_pct
FROM enriched
ORDER BY total_amount DESC
LIMIT 10;