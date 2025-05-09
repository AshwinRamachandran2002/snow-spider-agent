-- Percentage of “no‑tip” yellow‑taxi trips per pickup borough
WITH filtered_trips AS (
  SELECT
    t.pickup_location_id,
    -- tip_rate is 0 when total_amount is 0 (SAFE_DIVIDE avoids divide‑by‑zero)
    COALESCE(SAFE_DIVIDE(t.tip_amount * 100, t.total_amount), 0) AS tip_rate
  FROM `bigquery-public-data.new_york_taxi_trips.tlc_yellow_trips_2016` AS t
  WHERE DATE(t.pickup_datetime)  BETWEEN '2016-01-01' AND '2016-01-07'
    AND DATE(t.dropoff_datetime) BETWEEN '2016-01-01' AND '2016-01-07'
    AND t.dropoff_datetime > t.pickup_datetime        -- logical trip
    AND t.passenger_count  > 0                        -- at least one passenger
    AND t.trip_distance   >= 0                        -- non‑negative distance
    AND t.tip_amount      >= 0                        -- data‑quality checks
    AND t.tolls_amount    >= 0
    AND t.mta_tax         >= 0
    AND t.fare_amount     >= 0
    AND t.total_amount    >= 0
)

SELECT
  z.borough AS pickup_borough,
  ROUND(100 * COUNTIF(tip_rate = 0) / COUNT(*), 2) AS pct_no_tip
FROM filtered_trips AS t
JOIN `bigquery-public-data.new_york_taxi_trips.taxi_zone_geom` AS z
  ON t.pickup_location_id = z.zone_id
GROUP BY pickup_borough
ORDER BY pickup_borough;