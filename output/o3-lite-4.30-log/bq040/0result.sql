WITH valid_trips AS (
  SELECT
    z.borough AS pickup_borough,
    t.tip_amount,
    t.total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
    ON t.pickup_location_id = z.zone_id
  WHERE DATE(t.pickup_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count > 0
    AND t.trip_distance >= 0
    AND t.tip_amount   >= 0
    AND t.tolls_amount >= 0
    AND t.mta_tax      >= 0
    AND t.fare_amount  >= 0
    AND t.total_amount >= 0
    AND z.borough NOT IN ('EWR', 'Staten Island')
),
bucketized AS (
  SELECT
    pickup_borough,
    CASE
      WHEN tip_amount = 0 THEN 'no tip'
      WHEN SAFE_DIVIDE(100 * tip_amount, NULLIF(total_amount - tip_amount, 0)) <= 5  THEN 'Less than 5%'
      WHEN SAFE_DIVIDE(100 * tip_amount, NULLIF(total_amount - tip_amount, 0)) <= 10 THEN '5% to 10%'
      WHEN SAFE_DIVIDE(100 * tip_amount, NULLIF(total_amount - tip_amount, 0)) <= 15 THEN '10% to 15%'
      WHEN SAFE_DIVIDE(100 * tip_amount, NULLIF(total_amount - tip_amount, 0)) <= 20 THEN '15% to 20%'
      WHEN SAFE_DIVIDE(100 * tip_amount, NULLIF(total_amount - tip_amount, 0)) <= 25 THEN '20% to 25%'
      ELSE 'More than 25%'
    END AS tip_percent_bucket
  FROM valid_trips
)
SELECT
  pickup_borough,
  tip_percent_bucket,
  ROUND(
    COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough),
    4
  ) AS proportion_of_rides
FROM bucketized
GROUP BY pickup_borough, tip_percent_bucket
ORDER BY pickup_borough, tip_percent_bucket;