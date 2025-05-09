-- Top 10 most expensive (total fare) NYC taxi trips, 1–7 July 2016,
-- meeting the stated criteria
WITH base_trips AS (
  -- Yellow cabs -------------------------------------------------------------
  SELECT
    pickup_datetime                         AS pickup_dt,
    dropoff_datetime                        AS dropoff_dt,
    SAFE_CAST(passenger_count AS INT64)     AS passenger_cnt,
    SAFE_CAST(trip_distance   AS FLOAT64)   AS trip_miles,
    SAFE_CAST(fare_amount     AS FLOAT64)   AS fare_amt,
    SAFE_CAST(tip_amount      AS FLOAT64)   AS tip_amt,
    SAFE_CAST(tolls_amount    AS FLOAT64)   AS tolls_amt,
    SAFE_CAST(mta_tax         AS FLOAT64)   AS mta_tax,
    SAFE_CAST(total_amount    AS FLOAT64)   AS total_amt,
    pickup_location_id                       AS pu_zone_id,
    dropoff_location_id                      AS do_zone_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE pickup_datetime  >= '2016-07-01'
    AND pickup_datetime  <  '2016-07-08'
    AND dropoff_datetime >= '2016-07-01'
    AND dropoff_datetime <  '2016-07-08'

  UNION ALL
  -- Green cabs --------------------------------------------------------------
  SELECT
    pickup_datetime,
    dropoff_datetime,
    SAFE_CAST(passenger_count AS INT64),
    SAFE_CAST(trip_distance   AS FLOAT64),
    SAFE_CAST(fare_amount     AS FLOAT64),
    SAFE_CAST(tip_amount      AS FLOAT64),
    SAFE_CAST(tolls_amount    AS FLOAT64),
    SAFE_CAST(mta_tax         AS FLOAT64),
    SAFE_CAST(total_amount    AS FLOAT64),
    pickup_location_id,
    dropoff_location_id
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
  WHERE pickup_datetime  >= '2016-07-01'
    AND pickup_datetime  <  '2016-07-08'
    AND dropoff_datetime >= '2016-07-01'
    AND dropoff_datetime <  '2016-07-08'
),

filtered AS (
  SELECT
    *,
    TIMESTAMP_DIFF(dropoff_dt, pickup_dt, SECOND) AS trip_secs
  FROM base_trips
  WHERE passenger_cnt > 5
    AND trip_miles    >= 10
    AND dropoff_dt    >  pickup_dt            -- ensures positive duration
    -- eliminate any negative fare–related amounts
    AND fare_amt   >= 0
    AND tip_amt    >= 0
    AND tolls_amt  >= 0
    AND mta_tax    >= 0
    AND total_amt  >= 0
),

enriched AS (
  SELECT
    COALESCE(pu.zone_name,'Unknown') AS pickup_zone,
    COALESCE(do.zone_name,'Unknown') AS dropoff_zone,
    trip_secs,
    trip_miles,
    total_amt,
    ROUND(trip_miles * 3600 / trip_secs, 2)            AS speed_mph,
    ROUND(tip_amt * 100 / NULLIF(total_amt,0), 2)      AS tip_rate_pct
  FROM filtered f
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` pu
    ON pu.zone_id = f.pu_zone_id
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` do
    ON do.zone_id = f.do_zone_id
)

SELECT
  pickup_zone,
  dropoff_zone,
  trip_secs        AS trip_duration_seconds,
  speed_mph        AS driving_speed_mph,
  tip_rate_pct     AS tip_rate_percent
FROM enriched
ORDER BY total_amt DESC
LIMIT 10;