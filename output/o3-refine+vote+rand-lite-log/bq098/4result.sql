-- Percentage of “no‑tip” yellow‑taxi trips (Jan 1–7 2016) by pickup borough
WITH filtered_trips AS (
  SELECT
    t.*                              -- all trip columns
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE
        -- required 7‑day window (inclusive of Jan‑07‑2016)
        t.pickup_datetime  >= '2016-01-01'
    AND t.pickup_datetime  <  '2016-01-08'
    AND t.dropoff_datetime >= '2016-01-01'
    AND t.dropoff_datetime <  '2016-01-08'
        -- logical trip order
    AND t.dropoff_datetime >= t.pickup_datetime
        -- data‑quality filters
    AND t.passenger_count  >  0
    AND t.trip_distance    >= 0
    AND t.tip_amount       >= 0
    AND t.tolls_amount     >= 0
    AND t.mta_tax          >= 0
    AND t.fare_amount      >= 0
    AND t.total_amount     >= 0
),
trips_w_borough AS (
  SELECT
    z.borough,
    -- tip‑rate (%); 0 when total_amount = 0
    CASE
      WHEN t.total_amount > 0
           THEN (t.tip_amount * 100) / t.total_amount
      ELSE 0
    END AS tip_rate
  FROM filtered_trips AS t
  JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
    ON t.pickup_location_id = z.zone_id
  WHERE z.borough IS NOT NULL            -- keep trips mapped to a borough
)
SELECT
  borough AS pickup_borough,
  COUNTIF(tip_rate = 0)        AS no_tip_trips,
  COUNT(*)                     AS total_trips,
  ROUND(COUNTIF(tip_rate = 0) * 100.0 / COUNT(*), 4) AS pct_no_tip
FROM trips_w_borough
GROUP BY pickup_borough
ORDER BY pickup_borough;