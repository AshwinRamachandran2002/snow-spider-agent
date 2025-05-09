WITH filtered_trips AS (
  SELECT
    t.pickup_location_id,
    t.tip_amount,
    t.total_amount,
    SAFE_DIVIDE(t.tip_amount , t.total_amount) * 100 AS tip_pct
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        DATE(t.pickup_datetime , 'America/New_York') BETWEEN '2016-01-01' AND '2016-01-07'
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count > 0
    AND t.trip_distance  >= 0
    AND t.fare_amount    >= 0
    AND t.mta_tax        >= 0
    AND t.tolls_amount   >= 0
    AND t.tip_amount     >= 0
    AND t.total_amount   > 0
),
bucketed_trips AS (
  SELECT
    z.borough AS pickup_borough,
    CASE
      WHEN tip_amount = 0                THEN 'no tip'
      WHEN tip_pct <= 5                  THEN 'up to 5%'
      WHEN tip_pct <= 10                 THEN '5% to 10%'
      WHEN tip_pct <= 15                 THEN '10% to 15%'
      WHEN tip_pct <= 20                 THEN '15% to 20%'
      WHEN tip_pct <= 25                 THEN '20% to 25%'
      ELSE                                   'more than 25%'
    END AS tip_percent_bucket
  FROM filtered_trips ft
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` z
    ON ft.pickup_location_id = z.zone_id
  WHERE z.borough NOT IN ('EWR','Staten Island')
)
SELECT
  pickup_borough,
  tip_percent_bucket,
  ROUND( COUNT(*) / SUM(COUNT(*)) OVER (PARTITION BY pickup_borough), 4) AS proportion_of_rides
FROM bucketed_trips
GROUP BY pickup_borough, tip_percent_bucket
ORDER BY pickup_borough, tip_percent_bucket;