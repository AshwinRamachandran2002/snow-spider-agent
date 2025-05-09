/*  Top‑10 long, large‑party taxi trips in NYC (1 – 7 July 2016)  */
WITH all_2016_trips AS (      -- Yellow + Green fleets
  SELECT
    pickup_datetime,
    dropoff_datetime,
    CAST(pickup_location_id  AS STRING) AS pickup_id,
    CAST(dropoff_location_id AS STRING) AS dropoff_id,
    passenger_count,
    CAST(trip_distance AS FLOAT64)      AS trip_distance,
    CAST(fare_amount   AS FLOAT64)      AS fare_amount,
    CAST(tip_amount    AS FLOAT64)      AS tip_amount,
    CAST(tolls_amount  AS FLOAT64)      AS tolls_amount,
    CAST(mta_tax       AS FLOAT64)      AS mta_tax,
    CAST(total_amount  AS FLOAT64)      AS total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`

  UNION ALL

  SELECT
    pickup_datetime,
    dropoff_datetime,
    CAST(pickup_location_id  AS STRING),
    CAST(dropoff_location_id AS STRING),
    passenger_count,
    CAST(trip_distance AS FLOAT64),
    CAST(fare_amount   AS FLOAT64),
    CAST(tip_amount    AS FLOAT64),
    CAST(tolls_amount  AS FLOAT64),
    CAST(mta_tax       AS FLOAT64),
    CAST(total_amount  AS FLOAT64)
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
),

filtered AS (                 -- apply business rules
  SELECT *
  FROM all_2016_trips
  WHERE
        pickup_datetime  >= '2016-07-01 00:00:00' AND pickup_datetime  < '2016-07-08 00:00:00'
    AND dropoff_datetime >= '2016-07-01 00:00:00' AND dropoff_datetime < '2016-07-08 00:00:00'
    AND dropoff_datetime >  pickup_datetime                -- logical order
    AND passenger_count  >  5
    AND trip_distance    >= 10
    AND fare_amount  >= 0 AND tip_amount >= 0 AND tolls_amount >= 0
    AND mta_tax      >= 0 AND total_amount  > 0
),

with_zones AS (               -- attach zone names & derive metrics
  SELECT
    COALESCE(pick.zone_name , 'Unknown') AS pickup_zone,
    COALESCE(dropz.zone_name, 'Unknown') AS dropoff_zone,
    TIMESTAMP_DIFF(f.dropoff_datetime, f.pickup_datetime, SECOND)   AS duration_sec,
    f.trip_distance,
    f.total_amount,
    f.tip_amount
  FROM filtered AS f
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS pick
         ON f.pickup_id  = pick.zone_id
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS dropz
         ON f.dropoff_id = dropz.zone_id
)

SELECT
  pickup_zone,
  dropoff_zone,
  duration_sec                                        AS trip_duration_seconds,
  ROUND(trip_distance * 3600 / duration_sec , 2)      AS speed_mph,
  ROUND(tip_amount * 100 / total_amount , 2)          AS tip_rate_percent
FROM with_zones
WHERE duration_sec > 0                                  -- safeguard for division
ORDER BY total_amount DESC
LIMIT 10;