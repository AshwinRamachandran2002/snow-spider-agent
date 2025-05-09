-- Proportion of 2016-01-01 to 2016-01-07 yellow-cab rides in each tip bucket,
-- by pickup borough (excluding EWR & Staten Island zones and applying data-quality filters)
WITH trips AS (
  SELECT
    z.borough                                   AS pickup_borough,
    -- tip percentage: tip ÷ (total minus tip)  → multiply by 100 for %
    SAFE_DIVIDE(y.tip_amount,
                NULLIF(y.total_amount - y.tip_amount ,0)) * 100 AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
    ON z.zone_id = y.pickup_location_id
  WHERE DATE(y.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
        -- data-quality filters
        AND y.dropoff_datetime >  y.pickup_datetime
        AND y.passenger_count  > 0
        AND y.trip_distance    >= 0
        AND y.tip_amount       >= 0
        AND y.tolls_amount     >= 0
        AND y.mta_tax          >= 0
        AND y.fare_amount      >= 0
        AND y.total_amount     >= 0
        -- exclude unwanted pickup boroughs
        AND z.borough NOT IN ('EWR', 'Staten Island')
)
, bucketed AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_pct = 0                          THEN '0% (no tip)'
      WHEN tip_pct <= 5                         THEN 'up to 5%'
      WHEN tip_pct <= 10                        THEN '5% to 10%'
      WHEN tip_pct <= 15                        THEN '10% to 15%'
      WHEN tip_pct <= 20                        THEN '15% to 20%'
      WHEN tip_pct <= 25                        THEN '20% to 25%'
      ELSE                                           'more than 25%'
    END AS tip_bucket
  FROM trips
)
, counts AS (
  SELECT
    pickup_borough,
    tip_bucket,
    COUNT(*) AS rides
  FROM bucketed
  GROUP BY pickup_borough, tip_bucket
)
SELECT
  pickup_borough,
  tip_bucket,
  ROUND(
    rides / SUM(rides) OVER (PARTITION BY pickup_borough)
  , 4) AS proportion
FROM counts
ORDER BY pickup_borough, tip_bucket;