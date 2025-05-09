WITH duration_quantiles AS (
  SELECT
    NTILE(6) OVER (ORDER BY trip_seconds)      AS quantile_group,    -- six equal buckets
    ROUND(trip_seconds / 60.0)                 AS trip_minutes,      -- seconds → whole minutes
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 1 AND 3600                             -- keep trips 0–60 minutes
)

SELECT
  quantile_group,
  MIN(trip_minutes) AS min_trip_minutes,
  MAX(trip_minutes) AS max_trip_minutes,
  COUNT(*)          AS total_trips,
  AVG(fare)         AS average_fare
FROM duration_quantiles
GROUP BY quantile_group
ORDER BY quantile_group;