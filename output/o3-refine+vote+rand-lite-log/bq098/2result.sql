-- Percentage of “no‑tip” yellow‑cab trips (Jan 1‑7 2016) by pickup borough
WITH filtered_trips AS (
  SELECT
    t.pickup_location_id,
    /* tip‑rate per instructions: 0 when total_amount = 0 */
    CASE 
      WHEN t.total_amount = 0 THEN 0
      ELSE (t.tip_amount * 100) / t.total_amount
    END AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
    -- date window for BOTH pickup and drop‑off
    t.pickup_datetime  BETWEEN TIMESTAMP('2016-01-01 00:00:00') 
                          AND TIMESTAMP('2016-01-07 23:59:59')
    AND t.dropoff_datetime BETWEEN TIMESTAMP('2016-01-01 00:00:00') 
                              AND TIMESTAMP('2016-01-07 23:59:59')
    -- logical trip & data‑quality filters
    AND t.dropoff_datetime > t.pickup_datetime
    AND t.passenger_count > 0
    AND t.trip_distance  >= 0
    AND t.tip_amount     >= 0
    AND t.tolls_amount   >= 0
    AND t.mta_tax        >= 0
    AND t.fare_amount    >= 0
    AND t.total_amount   >= 0
),
with_borough AS (
  SELECT
    COALESCE(z.borough, 'Unknown') AS pickup_borough,
    f.tip_rate
  FROM filtered_trips AS f
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
         ON CAST(f.pickup_location_id AS STRING) = z.zone_id
)
SELECT
  pickup_borough,
  ROUND( 100 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END) 
              / COUNT(*), 4) AS pct_no_tip
FROM with_borough
GROUP BY pickup_borough
ORDER BY pct_no_tip DESC;