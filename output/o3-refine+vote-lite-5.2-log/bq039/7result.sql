-- Top‑10 longest (10+ mi) NYC taxi trips with >5 passengers during 1‑7 July 2016
WITH trips AS (
  ------------------------------------------------------------------
  -- 1.  Yellow cab trips -----------------------------------------
  ------------------------------------------------------------------
  SELECT
      'yellow' AS trip_source ,
      pickup_datetime ,
      dropoff_datetime ,
      CAST(passenger_count AS INT64)                AS passenger_count ,
      CAST(trip_distance   AS FLOAT64)              AS trip_distance  ,
      CAST(fare_amount     AS FLOAT64)              AS fare_amount    ,
      CAST(tip_amount      AS FLOAT64)              AS tip_amount     ,
      CAST(tolls_amount    AS FLOAT64)              AS tolls_amount   ,
      CAST(mta_tax         AS FLOAT64)              AS mta_tax        ,
      CAST(total_amount    AS FLOAT64)              AS total_amount   ,
      pickup_location_id ,
      dropoff_location_id
  FROM  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE DATE(pickup_datetime)  BETWEEN '2016-07-01' AND '2016-07-07'
    AND DATE(dropoff_datetime) BETWEEN '2016-07-01' AND '2016-07-07'

  UNION ALL

  ------------------------------------------------------------------
  -- 2.  Green cab trips  -----------------------------------------
  ------------------------------------------------------------------
  SELECT
      'green' ,
      pickup_datetime ,
      dropoff_datetime ,
      CAST(passenger_count AS INT64) ,
      CAST(trip_distance   AS FLOAT64) ,
      CAST(fare_amount     AS FLOAT64) ,
      CAST(tip_amount      AS FLOAT64) ,
      CAST(tolls_amount    AS FLOAT64) ,
      CAST(mta_tax         AS FLOAT64) ,
      CAST(total_amount    AS FLOAT64) ,
      pickup_location_id ,
      dropoff_location_id
  FROM  `bigquery-public-data.new_york_taxi_trips.tlc_green_trips_2016`
  WHERE DATE(pickup_datetime)  BETWEEN '2016-07-01' AND '2016-07-07'
    AND DATE(dropoff_datetime) BETWEEN '2016-07-01' AND '2016-07-07'
),

----------------------------------------------------------------------
-- 3.  Filtered set with derived metrics -----------------------------
----------------------------------------------------------------------
filtered AS (
  SELECT
      t.*,
      TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)      AS trip_duration_seconds ,
      trip_distance / (TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND)/3600.0) 
                                                                      AS speed_mph ,
      CASE WHEN total_amount > 0 
           THEN (tip_amount / total_amount) * 100 
      END                                                           AS tip_rate_pct
  FROM trips AS t
  WHERE passenger_count  > 5
    AND trip_distance     >= 10
    AND fare_amount       >= 0
    AND tip_amount        >= 0
    AND tolls_amount      >= 0
    AND mta_tax           >= 0
    AND total_amount      >= 0
    AND dropoff_datetime  >  pickup_datetime
    AND TIMESTAMP_DIFF(dropoff_datetime, pickup_datetime, SECOND) > 0
)

----------------------------------------------------------------------
-- 4.  Join to zone names and pick the top‑10 ------------------------
----------------------------------------------------------------------
SELECT
    p.zone_name                         AS pickup_zone ,
    d.zone_name                         AS dropoff_zone ,
    trip_duration_seconds ,
    ROUND(speed_mph   , 4)              AS speed_mph ,
    ROUND(tip_rate_pct, 4)              AS tip_rate_pct ,
    total_amount                        -- kept only for ordering; can be removed if desired
FROM filtered
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS p
       ON filtered.pickup_location_id  = p.zone_id
LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS d
       ON filtered.dropoff_location_id = d.zone_id
ORDER BY total_amount DESC
LIMIT 10;