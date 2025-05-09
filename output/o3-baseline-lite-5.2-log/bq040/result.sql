WITH cleaned_trips AS (
    SELECT
      z.borough                                               AS pickup_borough,
      -- tip percentage on the pre‑tip portion of the bill
      SAFE_MULTIPLY(
        SAFE_DIVIDE(t.tip_amount,
                    NULLIF(t.total_amount - t.tip_amount, 0)), 
        100.0
      )                                                      AS tip_rate_pct
    FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
    JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       AS z
      ON t.pickup_location_id = z.zone_id
    WHERE
          -- week of interest
          t.pickup_datetime >= TIMESTAMP('2016-01-01')
      AND  t.pickup_datetime <  TIMESTAMP('2016-01-08')
          -- data‑quality filters
      AND  t.dropoff_datetime > t.pickup_datetime
      AND  t.passenger_count  > 0
      AND  t.trip_distance   >= 0
      AND  t.tip_amount      >= 0
      AND  t.tolls_amount    >= 0
      AND  t.mta_tax         >= 0
      AND  t.fare_amount     >= 0
      AND  t.total_amount    >= 0
          -- exclude unwanted pickup boroughs
      AND  z.borough NOT IN ('EWR','Staten Island')
)

, trips_with_bucket AS (
    SELECT
      pickup_borough,
      CASE
        WHEN tip_rate_pct IS NULL OR tip_rate_pct = 0 THEN 'no tip'
        WHEN tip_rate_pct <=  5 THEN 'Less than 5%'
        WHEN tip_rate_pct <= 10 THEN '5% to 10%'
        WHEN tip_rate_pct <= 15 THEN '10% to 15%'
        WHEN tip_rate_pct <= 20 THEN '15% to 20%'
        WHEN tip_rate_pct <= 25 THEN '20% to 25%'
        ELSE                          'More than 25%'
      END AS tip_category
    FROM cleaned_trips
)

SELECT
  pickup_borough,
  tip_category,
  COUNT(*)                                         AS rides,
  ROUND( COUNT(*) 
         / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough) , 4) AS proportion
FROM trips_with_bucket
GROUP BY
  pickup_borough,
  tip_category
ORDER BY
  pickup_borough,
  tip_category;