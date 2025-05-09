WITH filtered AS (
  -- Keep only trips 0–60 minutes long
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 0 AND 3600
),
quantiled AS (
  -- Assign each trip to one of six equal-sized duration quantiles
  SELECT
    trip_minutes,
    fare,
    NTILE(6) OVER (ORDER BY trip_minutes) AS duration_group
  FROM filtered
)
-- For every quantile, return the summary metrics requested
SELECT
  duration_group                       AS quantile_group,
  MIN(trip_minutes)                    AS min_duration_min,
  MAX(trip_minutes)                    AS max_duration_min,
  COUNT(*)                             AS total_trips,
  AVG(fare)                            AS avg_fare
FROM quantiled
GROUP BY duration_group
ORDER BY duration_group;