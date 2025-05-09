/*  Proportion of 2016-01-01 → 2016-01-07 yellow-cab rides  
    (excluding EWR & Staten Island pickups) that fall in each
    tip-percentage bucket, by pickup borough.  */

WITH filtered AS (          -- quality-checked trips in the target week
  SELECT
    z.borough AS pickup_borough,
    SAFE_DIVIDE(t.tip_amount,
                NULLIF(t.total_amount - t.tip_amount,0)) * 100 AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
    ON t.pickup_location_id = z.zone_id
  WHERE t.pickup_datetime >= '2016-01-01'
    AND t.pickup_datetime <  '2016-01-08'          -- Jan-01 through Jan-07
    AND t.dropoff_datetime >  t.pickup_datetime
    AND t.passenger_count  >  0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
    AND z.borough NOT IN ('EWR','Staten Island')
),
bucketed AS (               -- assign each trip to a tip-percentage bucket
  SELECT
    pickup_borough,
    CASE
      WHEN tip_rate = 0                  THEN 'no tip'
      WHEN tip_rate <= 5                 THEN 'Less than 5%'
      WHEN tip_rate <= 10                THEN '5% to 10%'
      WHEN tip_rate <= 15                THEN '10% to 15%'
      WHEN tip_rate <= 20                THEN '15% to 20%'
      WHEN tip_rate <= 25                THEN '20% to 25%'
      ELSE                                   'More than 25%'
    END AS tip_bucket
  FROM filtered
),
counts AS (                 -- trips per borough / bucket
  SELECT
    pickup_borough,
    tip_bucket,
    COUNT(*) AS trips
  FROM bucketed
  GROUP BY pickup_borough, tip_bucket
),
totals AS (                 -- total trips per borough
  SELECT
    pickup_borough,
    SUM(trips) AS total_trips
  FROM counts
  GROUP BY pickup_borough
)
SELECT
  c.pickup_borough,
  c.tip_bucket,
  c.trips,
  ROUND(c.trips / t.total_trips, 4) AS proportion
FROM counts AS c
JOIN totals AS t USING (pickup_borough)
ORDER BY
  c.pickup_borough,
  CASE                          -- keep buckets in logical order
    WHEN c.tip_bucket = 'no tip'          THEN 0
    WHEN c.tip_bucket = 'Less than 5%'    THEN 1
    WHEN c.tip_bucket = '5% to 10%'       THEN 2
    WHEN c.tip_bucket = '10% to 15%'      THEN 3
    WHEN c.tip_bucket = '15% to 20%'      THEN 4
    WHEN c.tip_bucket = '20% to 25%'      THEN 5
    ELSE 6
  END;