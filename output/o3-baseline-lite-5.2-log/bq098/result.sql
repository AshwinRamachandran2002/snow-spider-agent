WITH trips_filtered AS (
  SELECT
    t.pickup_location_id,
    t.tip_amount,
    t.total_amount
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        -- trips picked up and dropped off between Jan‑01 and Jan‑07 (inclusive)
        t.pickup_datetime BETWEEN TIMESTAMP('2016-01-01 00:00:00') AND TIMESTAMP('2016-01-07 23:59:59')
    AND t.dropoff_datetime BETWEEN TIMESTAMP('2016-01-01 00:00:00') AND TIMESTAMP('2016-01-07 23:59:59')
        -- drop‑off must occur after pick‑up
    AND t.dropoff_datetime > t.pickup_datetime
        -- basic data‑quality filters
    AND t.passenger_count > 0
    AND t.trip_distance >= 0
    AND t.tip_amount  >= 0
    AND t.tolls_amount >= 0
    AND t.mta_tax      >= 0
    AND t.fare_amount  >= 0
    AND t.total_amount >= 0
    AND t.tip_amount   IS NOT NULL
    AND t.total_amount IS NOT NULL
),

trips_with_borough AS (
  SELECT
    z.borough AS pickup_borough,
    -- tip rate (%); treat as 0 when total_amount is 0
    CASE
      WHEN total_amount = 0 THEN 0
      ELSE (tip_amount * 100) / total_amount
    END AS tip_rate
  FROM trips_filtered AS f
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
         ON f.pickup_location_id = z.zone_id
)

SELECT
  pickup_borough,
  ROUND( 100 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END) / COUNT(*), 4 ) AS pct_no_tip
FROM trips_with_borough
GROUP BY pickup_borough
ORDER BY pickup_borough;