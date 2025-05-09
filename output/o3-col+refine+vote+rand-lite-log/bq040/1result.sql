-- Tip–bucket distribution by pickup-borough
WITH cleaned AS (   -- keep only valid 1–7 Jan 2016 yellow-cab trips
  SELECT
    z.borough                     AS pickup_borough,
    -- raw tip % (tip ÷ amount paid *before* tip)
    ROUND(
      100 * SAFE_DIVIDE(t.tip_amount,
                        NULLIF(t.total_amount - t.tip_amount ,0))
    ,2)                           AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        z
       ON t.pickup_location_id = z.zone_id
  WHERE t.pickup_datetime BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
    AND t.dropoff_datetime  >  t.pickup_datetime           -- logical trip
    AND t.passenger_count   >  0                           -- at least 1 rider
    AND t.trip_distance     >= 0                           -- non-negative
    AND t.tip_amount        >= 0
    AND t.tolls_amount      >= 0
    AND t.mta_tax           >= 0
    AND t.fare_amount       >= 0
    AND t.total_amount      >= 0
    AND z.borough NOT IN ('EWR', 'Staten Island')          -- exclude boroughs
),
bucketed AS (        -- map each trip to one of the seven tip buckets
  SELECT
    pickup_borough,
    CASE
      WHEN tip_pct = 0            THEN 'no tip'
      WHEN tip_pct <= 5           THEN 'Less than 5%'
      WHEN tip_pct <= 10          THEN '5% to 10%'
      WHEN tip_pct <= 15          THEN '10% to 15%'
      WHEN tip_pct <= 20          THEN '15% to 20%'
      WHEN tip_pct <= 25          THEN '20% to 25%'
      ELSE                             'More than 25%'
    END AS tip_bucket
  FROM cleaned
),
agg AS (             -- count rides in each (borough, bucket)
  SELECT
    pickup_borough,
    tip_bucket,
    COUNT(*) AS rides_in_bucket
  FROM bucketed
  GROUP BY pickup_borough, tip_bucket
),
with_pct AS (        -- convert counts to % of rides per borough
  SELECT
    pickup_borough,
    tip_bucket,
    ROUND(
      100 * rides_in_bucket /
      SUM(rides_in_bucket) OVER (PARTITION BY pickup_borough)
    ,2) AS pct_of_rides
  FROM agg
)
-- pivot into the requested wide format
SELECT *
FROM with_pct
PIVOT (
  MAX(pct_of_rides) FOR tip_bucket IN
  ('no tip',
   'Less than 5%',
   '5% to 10%',
   '10% to 15%',
   '15% to 20%',
   '20% to 25%',
   'More than 25%')
)
ORDER BY pickup_borough;