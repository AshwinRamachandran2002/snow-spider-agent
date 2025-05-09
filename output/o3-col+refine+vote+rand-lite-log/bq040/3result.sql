WITH base AS (
  SELECT
    z.borough,
    100 * SAFE_DIVIDE(tip_amount , total_amount - tip_amount) AS tip_rate
  FROM  `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016`  y
  JOIN  `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`         z
        ON z.zone_id = y.pickup_location_id          -- map pickup zone → borough
  WHERE DATE(y.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
        AND z.borough NOT IN ('EWR','Staten Island') -- exclude unwanted pickup boroughs
        AND y.dropoff_datetime > y.pickup_datetime    -- logical trip duration
        AND y.passenger_count  > 0                    -- at least one passenger
        AND y.trip_distance    >= 0                  -- non-negative numerics
        AND y.fare_amount      >= 0
        AND y.tip_amount       >= 0
        AND y.tolls_amount     >= 0
        AND y.mta_tax          >= 0
        AND y.total_amount     >= 0
),
bucketed AS (
  SELECT
    borough,
    CASE
      WHEN tip_rate = 0                          THEN 'no tip'
      WHEN tip_rate <= 5                         THEN 'Less than 5%'
      WHEN tip_rate > 5   AND tip_rate <= 10     THEN '5% to 10%'
      WHEN tip_rate > 10  AND tip_rate <= 15     THEN '10% to 15%'
      WHEN tip_rate > 15  AND tip_rate <= 20     THEN '15% to 20%'
      WHEN tip_rate > 20  AND tip_rate <= 25     THEN '20% to 25%'
      ELSE 'More than 25%'
    END AS tip_bucket
  FROM base
)
SELECT
  borough,
  tip_bucket,
  COUNT(*)                                                   AS rides,
  ROUND(100 * COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY borough),2)
                                                            AS pct_of_borough
FROM bucketed
GROUP BY borough, tip_bucket
ORDER BY borough, tip_bucket;