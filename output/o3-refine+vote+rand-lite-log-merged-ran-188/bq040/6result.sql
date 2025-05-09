-- Tip‑rate profile of NYC yellow‑cab rides (1–7 Jan 2016)
WITH valid_trips AS (
  SELECT
    z.borough                                  AS pickup_borough,
    -- tip % =  tip / (total – tip)
    (t.tip_amount * 100.0) /
    (t.total_amount - t.tip_amount)            AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       AS z
    ON t.pickup_location_id = z.zone_id
  WHERE
        -- 1‑7 Jan 2016 (inclusive, NYC is UTC‑5; timestamps are UTC)
        t.pickup_datetime >= '2016-01-01'
    AND t.pickup_datetime <  '2016-01-08'
        -- quality / logical filters
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count  > 0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
    AND (t.total_amount - t.tip_amount) > 0           -- avoid ÷0
        -- exclude EWR & Staten Island pickups
    AND z.borough NOT IN ('EWR','Staten Island')
)

, categorized AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_rate = 0                 THEN '0% (no tip)'
      WHEN tip_rate <=  5              THEN 'Up to 5%'
      WHEN tip_rate <= 10              THEN '5% to 10%'
      WHEN tip_rate <= 15              THEN '10% to 15%'
      WHEN tip_rate <= 20              THEN '15% to 20%'
      WHEN tip_rate <= 25              THEN '20% to 25%'
      ELSE                                'More than 25%'
    END AS tip_category
  FROM valid_trips
)

SELECT
  pickup_borough,
  tip_category,
  COUNT(*)                                                  AS trip_count,
  ROUND( COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough), 4)
                                                           AS proportion
FROM categorized
GROUP BY
  pickup_borough,
  tip_category
ORDER BY
  pickup_borough,
  tip_category;