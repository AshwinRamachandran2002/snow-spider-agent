WITH filtered AS (
  SELECT
    trip_seconds,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0              -- exclude missing / zero-length rides
    AND trip_seconds <= 3600          -- keep trips ≤ 60 minutes
),
bucketed AS (
  SELECT
    NTILE(6) OVER (ORDER BY trip_seconds) AS quantile,  -- 6 equal-sized duration buckets
    trip_seconds,
    fare
  FROM filtered
)
SELECT
  quantile,
  ROUND(MIN(trip_seconds) / 60.0) AS min_trip_minutes,  -- rounded minutes (nearest whole)
  ROUND(MAX(trip_seconds) / 60.0) AS max_trip_minutes,
  COUNT(*)                       AS total_trips,
  ROUND(AVG(fare), 2)            AS avg_fare
FROM bucketed
GROUP BY quantile
ORDER BY quantile;