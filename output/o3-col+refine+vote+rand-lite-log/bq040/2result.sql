-- Proportion of NYC yellow-cab rides in each tip bucket, by pickup borough
WITH jan_week_2016 AS (
  SELECT
    z.borough                                         AS pickup_borough,
    -- tip percentage on the pretax / pre-tip part of the bill
    100 * SAFE_DIVIDE(t.tip_amount ,
                      NULLIF(t.total_amount - t.tip_amount ,0))         AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       z
    ON t.pickup_location_id = z.zone_id
  WHERE t.pickup_datetime BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
    -- quality filters -------------------------------------------------------
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count  > 0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
    -- exclude EWR and Staten Island pickups --------------------------------
    AND z.borough NOT IN ('EWR','Staten Island')
),
bucketed AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_pct IS NULL OR tip_pct = 0                         THEN 'no tip'
      WHEN tip_pct <= 5                                           THEN 'Less than 5%'
      WHEN tip_pct > 5  AND tip_pct <= 10                         THEN '5% to 10%'
      WHEN tip_pct > 10 AND tip_pct <= 15                         THEN '10% to 15%'
      WHEN tip_pct > 15 AND tip_pct <= 20                         THEN '15% to 20%'
      WHEN tip_pct > 20 AND tip_pct <= 25                         THEN '20% to 25%'
      ELSE 'More than 25%' END                                    AS tip_bucket
  FROM jan_week_2016
)
SELECT
  pickup_borough,
  tip_bucket,
  COUNT(*) AS rides,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough),2)
         AS pct_of_borough
FROM bucketed
GROUP BY pickup_borough, tip_bucket
ORDER BY pickup_borough, tip_bucket;