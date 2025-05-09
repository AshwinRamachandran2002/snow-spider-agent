-- Percentage of “no-tip” yellow-cab trips by pickup borough  
-- (Jan 1 – Jan 7, 2016)

WITH jan_week AS (
  SELECT
    y.pickup_location_id,
    y.tip_amount,
    y.total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS y
  WHERE DATE(y.pickup_datetime)  BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(y.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND y.dropoff_datetime > y.pickup_datetime
    AND y.passenger_count  > 0
    AND y.trip_distance    >= 0
    AND y.tip_amount       >= 0
    AND y.tolls_amount     >= 0
    AND y.mta_tax          >= 0
    AND y.fare_amount      >= 0
    AND y.total_amount     >= 0
),
labeled AS (
  SELECT
    z.borough AS pickup_borough,
    CASE
      WHEN total_amount > 0 THEN ROUND(tip_amount * 100 / total_amount, 2)
      ELSE 0
    END AS tip_rate
  FROM jan_week AS w
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
    ON w.pickup_location_id = z.zone_id
)
SELECT
  pickup_borough,
  ROUND(
    COUNTIF(tip_rate = 0) * 100.0 / COUNT(*),
    2
  ) AS percent_no_tip
FROM labeled
GROUP BY pickup_borough
ORDER BY percent_no_tip DESC;