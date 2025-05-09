/*  Percentage of “no‑tip” yellow‑cab trips by pickup borough
    for rides that both started and ended between
    1 Jan 2016 00:00:00 and 7 Jan 2016 23:59:59 (inclusive)          */

WITH filtered_trips AS (
  SELECT
    z.borough                       AS pickup_borough,
    /* tip‑rate = 0 when total_amount = 0,
       else (tip_amount*100) / total_amount                           */
    CASE
      WHEN t.total_amount IS NULL OR t.total_amount = 0 THEN 0
      ELSE SAFE_DIVIDE(t.tip_amount * 100, t.total_amount)
    END                           AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` t
  LEFT JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`  z
    ON t.pickup_location_id = z.zone_id
  WHERE
        -- date window (inclusive)
        t.pickup_datetime  >= TIMESTAMP('2016-01-01 00:00:00')
    AND  t.pickup_datetime  <  TIMESTAMP('2016-01-08 00:00:00')
    AND  t.dropoff_datetime >= TIMESTAMP('2016-01-01 00:00:00')
    AND  t.dropoff_datetime <  TIMESTAMP('2016-01-08 00:00:00')
        -- logical trip constraints
    AND  t.dropoff_datetime >  t.pickup_datetime
    AND  t.passenger_count  >  0
        -- non‑negative numeric values
    AND  t.trip_distance    >= 0
    AND  t.tip_amount       >= 0
    AND  t.tolls_amount     >= 0
    AND  t.mta_tax          >= 0
    AND  t.fare_amount      >= 0
    AND  t.total_amount     >= 0
)

SELECT
  pickup_borough,
  ROUND( 100 * SUM(CASE WHEN tip_rate = 0 THEN 1 ELSE 0 END)
               / COUNT(*), 2)      AS pct_no_tip
FROM filtered_trips
GROUP BY pickup_borough
ORDER BY pct_no_tip DESC;