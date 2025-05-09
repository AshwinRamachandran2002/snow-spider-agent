WITH filtered AS (
  -- Keep trips that last between 0-60 minutes (1-3 600 seconds),
  -- and convert duration to minutes
  SELECT
    trip_seconds / 60.0 AS duration_minutes,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 1 AND 3600
),
labeled AS (
  -- Assign each trip to one of six equal-sized quantile groups
  SELECT
    duration_minutes,
    fare,
    NTILE(6) OVER (ORDER BY duration_minutes) AS quantile_group
  FROM filtered
)
SELECT
  quantile_group,
  ROUND(MIN(duration_minutes)) AS min_duration_minutes,
  ROUND(MAX(duration_minutes)) AS max_duration_minutes,
  COUNT(*)                    AS total_trips,
  ROUND(AVG(fare), 2)         AS avg_fare
FROM labeled
GROUP BY quantile_group
ORDER BY quantile_group;