/*  Proportion of 1‑7 Jan 2016 yellow‑taxi trips that fall into each
    tip‑percentage bucket, broken‑out by the trip’s pick‑up borough        */

WITH trips AS (   -- 1️⃣ valid rides with pick‑up borough attached
  SELECT
    z.borough,
    SAFE_DIVIDE(t.tip_amount,
                NULLIF(t.total_amount - t.tip_amount ,0)) * 100 AS tip_pct
  FROM   `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN   `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
         ON z.zone_id = t.pickup_location_id
  WHERE  DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND  t.dropoff_datetime  >  t.pickup_datetime      -- logical trip
    AND  t.passenger_count   >  0                      -- at least one rider
    AND  t.trip_distance     >= 0
    AND  t.tip_amount        >= 0
    AND  t.tolls_amount      >= 0
    AND  t.mta_tax           >= 0
    AND  t.fare_amount       >= 0
    AND  t.total_amount      >= 0
    AND  z.borough NOT IN ('EWR','Staten Island')      -- exclude per spec
),

bucketed AS (     -- 2️⃣ assign each ride to a tip‑percentage bucket
  SELECT
    borough,
    CASE
      WHEN tip_pct = 0                THEN 'no tip'
      WHEN tip_pct <=  5              THEN 'Less than 5%'
      WHEN tip_pct <= 10              THEN '5% to 10%'
      WHEN tip_pct <= 15              THEN '10% to 15%'
      WHEN tip_pct <= 20              THEN '15% to 20%'
      WHEN tip_pct <= 25              THEN '20% to 25%'
      ELSE                             'More than 25%'
    END AS tip_bucket
  FROM trips
),

agg AS (         -- 3️⃣ count rides per (borough , bucket)
  SELECT
    borough,
    tip_bucket,
    COUNT(*)                                   AS trips_in_bucket,
    SUM(COUNT(*)) OVER (PARTITION BY borough)  AS total_trips
  FROM bucketed
  GROUP BY borough, tip_bucket
)

-- 4️⃣ final proportions (percentage of rides in each bucket)
SELECT
  borough,
  tip_bucket,
  ROUND(100 * trips_in_bucket / total_trips , 2) AS percent_of_rides
FROM   agg
ORDER BY borough, percent_of_rides DESC;