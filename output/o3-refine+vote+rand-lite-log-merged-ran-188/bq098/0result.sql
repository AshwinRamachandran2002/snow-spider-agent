/* Percentage of yellow-taxi trips (Jan 1–7 2016) with no tip, by pickup borough */
SELECT
  z.borough                                        AS pickup_borough,
  ROUND(
        100 * SUM(
                  CASE
                      /* treat total_amount = 0 or computed tip_rate = 0 as “no-tip” */
                      WHEN t.total_amount = 0 THEN 1
                      WHEN (t.tip_amount * 100) / t.total_amount = 0 THEN 1
                      ELSE 0
                  END
              ) / COUNT(*)
       , 2)                                        AS pct_no_tip_trips
FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
  ON CAST(t.pickup_location_id AS STRING) = z.zone_id
WHERE t.pickup_datetime BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
  AND t.dropoff_datetime  >  t.pickup_datetime         -- dropoff after pickup
  AND t.passenger_count   >  0                         -- positive passengers
  AND t.trip_distance     >= 0
  AND t.tip_amount        >= 0
  AND t.tolls_amount      >= 0
  AND t.mta_tax           >= 0
  AND t.fare_amount       >= 0
  AND t.total_amount      >= 0
GROUP BY pickup_borough
ORDER BY pct_no_tip_trips DESC;