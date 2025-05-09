/*  Six‑quantile summary of Chicago taxi trips that last 0–60 minutes           */

WITH filtered AS (
  SELECT
    trip_seconds / 60.0             AS trip_minutes,     -- duration in minutes
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0            -- positive durations only
    AND trip_seconds <= 60 * 60     -- up to 60 minutes (3 600 seconds)
),

-- Assign each trip to one of six equal‑size quantile groups by duration
sextiled AS (
  SELECT
    NTILE(6) OVER (ORDER BY trip_minutes) AS quantile_group,
    trip_minutes,
    fare
  FROM filtered
)

SELECT
  quantile_group,
  ROUND(MIN(trip_minutes)) AS min_duration_minutes,
  ROUND(MAX(trip_minutes)) AS max_duration_minutes,
  COUNT(*)                 AS total_trips,
  ROUND(AVG(fare), 4)      AS avg_fare
FROM sextiled
GROUP BY quantile_group
ORDER BY quantile_group;