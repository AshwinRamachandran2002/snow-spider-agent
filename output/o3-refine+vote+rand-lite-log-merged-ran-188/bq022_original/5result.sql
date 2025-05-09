WITH eligible_trips AS (
  SELECT
    trip_seconds,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds IS NOT NULL         -- keep only rows with a duration value
    AND trip_seconds > 0             -- positive trips
    AND trip_seconds <= 60 * 60      -- 0–60 minutes (≤ 3 600 seconds)
),

-- assign each trip to one of six equal‑sized duration quantiles
quantiled AS (
  SELECT
    *,
    NTILE(6) OVER (ORDER BY trip_seconds) AS quantile_group
  FROM eligible_trips
)

SELECT
  quantile_group,
  MIN(ROUND(trip_seconds / 60)) AS min_duration_minutes,
  MAX(ROUND(trip_seconds / 60)) AS max_duration_minutes,
  COUNT(*)                      AS total_trips,
  ROUND(AVG(fare), 4)           AS avg_fare
FROM quantiled
GROUP BY quantile_group
ORDER BY quantile_group;