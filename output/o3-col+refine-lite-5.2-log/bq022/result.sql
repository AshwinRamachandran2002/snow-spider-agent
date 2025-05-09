-- 6‑quantile statistics for trips lasting 0–60 minutes
WITH filtered AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,   -- duration in whole minutes
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 1 AND 3600           -- keep trips >0 sec and ≤60 min
),
ranked AS (
  SELECT
    *,
    NTILE(6) OVER (ORDER BY trip_minutes) AS duration_quantile
  FROM filtered
)
SELECT
  duration_quantile              AS quantile_group,
  MIN(trip_minutes)              AS min_trip_minutes,
  MAX(trip_minutes)              AS max_trip_minutes,
  COUNT(*)                       AS total_trips,
  AVG(fare)                      AS average_fare
FROM ranked
GROUP BY duration_quantile
ORDER BY quantile_group;