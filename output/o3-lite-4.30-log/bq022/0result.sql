WITH eligible AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,       -- duration in whole minutes (rounded)
    fare,
    NTILE(6) OVER (ORDER BY trip_seconds) AS quantile  -- six equal‑frequency groups
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 1 AND 3600               -- consider trips >0 and ≤60 minutes
)
SELECT
  MIN(trip_minutes)            AS min_trip_duration,
  MAX(trip_minutes)            AS max_trip_duration,
  COUNT(*)                     AS total_trips,
  ROUND(AVG(fare), 4)          AS avg_fare
FROM eligible
GROUP BY quantile
ORDER BY quantile;