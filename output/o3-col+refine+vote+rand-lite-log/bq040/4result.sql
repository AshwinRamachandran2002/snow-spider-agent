-- Proportion of 1–7 Jan 2016 yellow-cab rides that fall into each tip-rate
-- bucket, by pickup borough (excluding EWR and Staten Island)

WITH base_trips AS (
  SELECT
    pickup_location_id,
    -- tip %; SAFE_DIVIDE avoids division-by-zero
    SAFE_DIVIDE(tip_amount , NULLIF(fare_amount ,0))*100 AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`
  WHERE pickup_datetime >= '2016-01-01'
    AND pickup_datetime <  '2016-01-08'               -- 1 – 7 Jan inclusive
    AND dropoff_datetime  >  pickup_datetime          -- logical trip
    AND passenger_count   >  0
    AND trip_distance     >= 0
    AND tip_amount        >= 0
    AND tolls_amount      >= 0
    AND mta_tax           >= 0
    AND fare_amount       >= 0
    AND total_amount      >= 0
),
classified AS (
  SELECT
    z.borough AS pickup_borough,
    CASE
      WHEN tip_pct = 0                      THEN 'no tip'
      WHEN tip_pct <=  5                   THEN 'Less than 5%'
      WHEN tip_pct <= 10                   THEN '5% to 10%'
      WHEN tip_pct <= 15                   THEN '10% to 15%'
      WHEN tip_pct <= 20                   THEN '15% to 20%'
      WHEN tip_pct <= 25                   THEN '20% to 25%'
      ELSE                                    'More than 25%'
    END AS tip_bucket
  FROM base_trips t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON z.zone_id = t.pickup_location_id
  WHERE z.borough NOT IN ('EWR' , 'Staten Island')
),
bucket_counts AS (
  SELECT
    pickup_borough,
    tip_bucket,
    COUNT(*) AS trips_in_bucket
  FROM classified
  GROUP BY pickup_borough , tip_bucket
)

SELECT
  pickup_borough,
  tip_bucket,
  trips_in_bucket,
  ROUND(
    trips_in_bucket
    / SUM(trips_in_bucket) OVER (PARTITION BY pickup_borough)
  ,4) AS proportion_of_rides
FROM bucket_counts
ORDER BY pickup_borough , tip_bucket;