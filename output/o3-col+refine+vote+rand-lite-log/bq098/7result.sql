/*  Percentage of “no-tip” yellow-cab trips by pickup borough
    Jan 1 – Jan 7, 2016 (inclusive)                                    */

SELECT
  z.borough AS pickup_borough,
  ROUND(
        100 * SUM(
              CASE
                /* “no tip” ⇒ tip_rate = 0
                   – if total_amount > 0 → tip_amount must be 0
                   – if total_amount = 0 → treat as no-tip            */
                WHEN (CASE WHEN t.total_amount > 0
                           THEN t.tip_amount = 0
                           ELSE TRUE
                      END)
                THEN 1
                ELSE 0
              END)
        / COUNT(*)
       , 2)                       AS pct_no_tip
FROM   `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN   `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
  ON   t.pickup_location_id = z.zone_id
WHERE  -- trips picked-up and dropped-off Jan 1–7 2016
       t.pickup_datetime  >= '2016-01-01'
   AND t.pickup_datetime  <  '2016-01-08'
   AND t.dropoff_datetime >= '2016-01-01'
   AND t.dropoff_datetime <  '2016-01-08'
       -- required data-quality filters
   AND t.dropoff_datetime >  t.pickup_datetime
   AND t.passenger_count  >  0
   AND t.trip_distance    >= 0
   AND t.tip_amount       >= 0
   AND t.tolls_amount     >= 0
   AND t.mta_tax          >= 0
   AND t.fare_amount      >= 0
   AND t.total_amount     >= 0
GROUP BY
  pickup_borough
ORDER BY
  pct_no_tip DESC;