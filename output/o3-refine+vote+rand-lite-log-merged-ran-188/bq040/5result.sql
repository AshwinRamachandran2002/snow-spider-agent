WITH base AS (
  SELECT
    t.pickup_datetime,
    t.dropoff_datetime,
    t.passenger_count,
    t.trip_distance,
    t.tip_amount,
    t.tolls_amount,
    t.mta_tax,
    t.fare_amount,
    t.total_amount,
    z.borough AS pickup_borough
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`         AS z
    ON t.pickup_location_id = z.zone_id
  WHERE
        t.pickup_datetime BETWEEN '2016-01-01 00:00:00' AND '2016-01-08 00:00:00'
    AND t.dropoff_datetime  >  t.pickup_datetime
    AND t.passenger_count   >  0
    AND t.trip_distance     >= 0
    AND t.tip_amount        >= 0
    AND t.tolls_amount      >= 0
    AND t.mta_tax           >= 0
    AND t.fare_amount       >= 0
    AND t.total_amount      >= 0
    AND z.borough NOT IN ('EWR', 'Staten Island')
),
tips AS (
  SELECT
    pickup_borough,
    -- Tip % = 100 * tip / (total – tip).  Skip rows where denominator ≤ 0.
    SAFE_DIVIDE(CAST(tip_amount AS FLOAT64) * 100,
                NULLIF(CAST(total_amount AS FLOAT64) - CAST(tip_amount AS FLOAT64), 0)
               ) AS tip_pct
  FROM base
),
categorized AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_pct IS NULL                THEN 'Unknown'
      WHEN tip_pct = 0                    THEN '0% (no tip)'
      WHEN tip_pct  > 0  AND tip_pct <= 5 THEN 'Up to 5%'
      WHEN tip_pct  > 5  AND tip_pct <=10 THEN '5%–10%'
      WHEN tip_pct  >10  AND tip_pct <=15 THEN '10%–15%'
      WHEN tip_pct  >15  AND tip_pct <=20 THEN '15%–20%'
      WHEN tip_pct  >20  AND tip_pct <=25 THEN '20%–25%'
      WHEN tip_pct  >25                   THEN 'More than 25%'
    END AS tip_category
  FROM tips
  WHERE tip_pct IS NOT NULL   -- discard rows with undefined percentage
)
SELECT
  pickup_borough,
  tip_category,
  COUNT(*)                                       AS ride_count,
  ROUND(COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough), 4) AS proportion_of_rides
FROM categorized
GROUP BY pickup_borough, tip_category
ORDER BY pickup_borough, tip_category;