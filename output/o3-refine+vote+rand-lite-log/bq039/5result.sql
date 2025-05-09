-- Top 10 most expensive (total fare) NYC taxi trips
--   • Between 2016‑07‑01 00:00:00 and 2016‑07‑07 23:59:59
--   • Passenger count  > 5
--   • Trip distance    ≥ 10 miles
--   • All monetary fields non‑negative
--   • Drop‑off time strictly after pick‑up time
-- Returns: pickup zone, drop‑off zone, trip duration (sec), speed (mph), tip‑rate (%)
WITH union_trips AS (        -- yellow + green fleets for 2016
  SELECT
    pickup_datetime,
    dropoff_datetime,
    CAST(passenger_count        AS INT64)   AS passenger_count,
    CAST(trip_distance          AS FLOAT64) AS trip_distance,
    CAST(fare_amount            AS FLOAT64) AS fare_amount,
    CAST(tip_amount             AS FLOAT64) AS tip_amount,
    CAST(tolls_amount           AS FLOAT64) AS tolls_amount,
    CAST(mta_tax                AS FLOAT64) AS mta_tax,
    CAST(total_amount           AS FLOAT64) AS total_amount,
    CAST(pickup_location_id     AS STRING)  AS pickup_location_id,
    CAST(dropoff_location_id    AS STRING)  AS dropoff_location_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE pickup_datetime  >= '2016-07-01 00:00:00'
    AND pickup_datetime  <  '2016-07-08 00:00:00'
    AND dropoff_datetime >= '2016-07-01 00:00:00'
    AND dropoff_datetime <  '2016-07-08 00:00:00'

  UNION ALL

  SELECT
    pickup_datetime,
    dropoff_datetime,
    CAST(passenger_count        AS INT64),
    CAST(trip_distance          AS FLOAT64),
    CAST(fare_amount            AS FLOAT64),
    CAST(tip_amount             AS FLOAT64),
    CAST(tolls_amount           AS FLOAT64),
    CAST(mta_tax                AS FLOAT64),
    CAST(total_amount           AS FLOAT64),
    CAST(pickup_location_id     AS STRING),
    CAST(dropoff_location_id    AS STRING)
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
  WHERE pickup_datetime  >= '2016-07-01 00:00:00'
    AND pickup_datetime  <  '2016-07-08 00:00:00'
    AND dropoff_datetime >= '2016-07-01 00:00:00'
    AND dropoff_datetime <  '2016-07-08 00:00:00'
),
filtered AS (
  SELECT *
  FROM union_trips
  WHERE passenger_count            >  5
    AND trip_distance              >= 10
    AND dropoff_datetime           >  pickup_datetime
    AND COALESCE(fare_amount ,0)   >= 0
    AND COALESCE(tip_amount  ,0)   >= 0
    AND COALESCE(tolls_amount,0)   >= 0
    AND COALESCE(mta_tax     ,0)   >= 0
    AND COALESCE(total_amount,0)   >= 0
    AND total_amount IS NOT NULL
),
enriched AS (                  -- add zone names + derive metrics
  SELECT
    pu.zone_name AS pickup_zone,
    do.zone_name AS dropoff_zone,
    TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) AS trip_duration_seconds,
    ROUND(trip_distance /
          (TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)/3600.0), 4) AS speed_mph,
    ROUND(tip_amount / NULLIF(total_amount,0) * 100, 4)                          AS tip_rate_percent,
    total_amount
  FROM filtered f
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` pu
         ON pu.zone_id = f.pickup_location_id
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` do
         ON do.zone_id = f.dropoff_location_id
)
SELECT
  pickup_zone,
  dropoff_zone,
  trip_duration_seconds,
  speed_mph,
  tip_rate_percent
FROM enriched
ORDER BY total_amount DESC, trip_duration_seconds DESC   -- secondary tie‑breaker
LIMIT 10;