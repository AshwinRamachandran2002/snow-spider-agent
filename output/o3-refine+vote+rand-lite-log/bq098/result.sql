-- Share of yellow‑taxi trips with no tip (Jan 1–7 2016) by pickup borough
WITH trips_2016_jan1_7 AS (
  SELECT
    z.borough                                                  AS pickup_borough,
    -- tip‑rate (%) – treated as 0 when total_amount is 0 to avoid division by 0
    CASE
      WHEN t.total_amount > 0 THEN (t.tip_amount * 100) / t.total_amount
      ELSE 0
    END                                                       AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom`        AS z
    ON t.pickup_location_id = z.zone_id
  WHERE
        -- both pickup and drop‑off between 1 Jan and 7 Jan 2016 (inclusive)
        t.pickup_datetime  BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
    AND t.dropoff_datetime BETWEEN '2016-01-01' AND '2016-01-07 23:59:59'
        -- drop‑off must occur after pickup
    AND t.dropoff_datetime > t.pickup_datetime
        -- trip / fare quality filters
    AND t.passenger_count  > 0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
)

SELECT
  pickup_borough,
  ROUND( 100 * COUNTIF(tip_rate = 0) / COUNT(*), 4 ) AS pct_no_tip -- percentage with 4‑decimal precision
FROM trips_2016_jan1_7
GROUP BY pickup_borough
ORDER BY pickup_borough;