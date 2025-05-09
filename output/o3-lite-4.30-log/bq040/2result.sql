WITH filtered_trips AS (
  SELECT
    g.borough AS pickup_borough,
    SAFE_MULTIPLY(100, SAFE_DIVIDE(t.tip_amount, t.fare_amount)) AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS g
    ON t.pickup_location_id = g.zone_id
  WHERE DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count  > 0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount       > 0          -- avoid division by zero
    AND t.total_amount     >= 0
    AND g.borough NOT IN ('EWR', 'Staten Island')
),
bucketed AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_rate = 0                     THEN 'no tip'
      WHEN tip_rate <=  5                  THEN 'up to 5%'
      WHEN tip_rate <= 10                  THEN '5% to 10%'
      WHEN tip_rate <= 15                  THEN '10% to 15%'
      WHEN tip_rate <= 20                  THEN '15% to 20%'
      WHEN tip_rate <= 25                  THEN '20% to 25%'
      ELSE                                      'more than 25%'
    END AS tip_percent_bucket
  FROM filtered_trips
)
SELECT
  pickup_borough,
  tip_percent_bucket,
  ROUND(
    COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough)
  , 4) AS proportion_of_rides
FROM bucketed
GROUP BY pickup_borough, tip_percent_bucket
ORDER BY pickup_borough, tip_percent_bucket;