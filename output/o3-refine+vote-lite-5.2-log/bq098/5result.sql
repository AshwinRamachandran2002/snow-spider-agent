/*  Percentage of “no‑tip” yellow‑taxi trips (Jan 1‑7 2016) by pickup borough  */
WITH trips_filtered AS (
  SELECT
    tz.borough                         AS pickup_borough,
    /* tip‑rate: 0 when total_amount is 0 (or NULL) */
    CASE
      WHEN t.total_amount IS NULL OR t.total_amount = 0 THEN 0
      ELSE (COALESCE(t.tip_amount, 0) * 100) / t.total_amount
    END                               AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`       AS tz
        ON tz.zone_id = t.pickup_location_id
  WHERE
        /* pickup & dropoff between 2016‑01‑01 and 2016‑01‑07 (inclusive) */
        DATE(t.pickup_datetime , 'America/New_York')  BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(t.dropoff_datetime, 'America/New_York')  BETWEEN '2016-01-01' AND '2016-01-07'
        /* dropoff must occur after pickup                                                 */
    AND t.dropoff_datetime > t.pickup_datetime
        /* data‑quality filters                                                           */
    AND t.passenger_count > 0
    AND t.trip_distance  >= 0
    AND t.tip_amount     >= 0
    AND t.tolls_amount   >= 0
    AND t.mta_tax        >= 0
    AND t.fare_amount    >= 0
    AND t.total_amount   >= 0
)
SELECT
  pickup_borough          AS borough,
  ROUND( 100.0 * COUNTIF(tip_rate = 0) / COUNT(*), 4 ) AS pct_no_tip
FROM trips_filtered
GROUP BY borough
ORDER BY pct_no_tip DESC;