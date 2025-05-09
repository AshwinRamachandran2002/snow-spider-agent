WITH trips AS (
  -- 1.  Pull yellow-cab trips in the study window
  SELECT
    pickup_location_id,
    -- raw tip % (relative to the pre-tip amount)
    ROUND(100 * tip_amount /
          NULLIF(total_amount - tip_amount,0),2) AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE pickup_datetime BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
        -- data-quality filters
        AND dropoff_datetime  >  pickup_datetime
        AND passenger_count   >  0
        AND trip_distance     >= 0
        AND tip_amount        >= 0
        AND tolls_amount      >= 0
        AND mta_tax           >= 0
        AND fare_amount       >= 0
        AND total_amount      >= 0
),
trips_with_borough AS (
  -- 2.  Attach the pickup borough and tip bucket
  SELECT
    z.borough AS pickup_borough,
    CASE
      WHEN tip_pct  = 0                        THEN 'no tip'
      WHEN tip_pct <= 5                        THEN 'Less than 5%'
      WHEN tip_pct <= 10                       THEN '5% to 10%'
      WHEN tip_pct <= 15                       THEN '10% to 15%'
      WHEN tip_pct <= 20                       THEN '15% to 20%'
      WHEN tip_pct <= 25                       THEN '20% to 25%'
      ELSE                                          'More than 25%'
    END AS tip_bucket
  FROM trips t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON t.pickup_location_id = z.zone_id
  WHERE z.borough NOT IN ('EWR','Staten Island')        -- exclusions
),
bucket_counts AS (
  -- 3.  Count rides in each tip bucket per borough
  SELECT
    pickup_borough,
    tip_bucket,
    COUNT(*) AS rides
  FROM trips_with_borough
  GROUP BY pickup_borough, tip_bucket
),
borough_totals AS (
  -- 4.  Total rides per borough (for proportions)
  SELECT
    pickup_borough,
    COUNT(*) AS total_rides
  FROM trips_with_borough
  GROUP BY pickup_borough
)
-- 5.  Final result: rides & proportion within each tip bucket
SELECT
  b.pickup_borough,
  b.tip_bucket,
  b.rides,
  ROUND(b.rides / t.total_rides, 4) AS proportion_of_rides
FROM bucket_counts b
JOIN borough_totals t
  ON b.pickup_borough = t.pickup_borough
ORDER BY b.pickup_borough, b.tip_bucket;