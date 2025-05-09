WITH base AS (
  SELECT
    CAST(ROUND(trip_seconds / 60.0) AS INT64) AS duration_min,  -- rounded duration in minutes
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
),
filtered AS (
  SELECT
    duration_min,
    fare,
    NTILE(10) OVER (ORDER BY duration_min) AS decile            -- ten equal‑sized quantile groups
  FROM base
  WHERE duration_min BETWEEN 1 AND 50                           -- keep trips 1‑50 minutes
)
SELECT
  FORMAT(
    '%02dm to %02dm',
    CAST(MIN(duration_min) AS INT64),
    CAST(MAX(duration_min) AS INT64)
  ) AS time_range,
  COUNT(*)                          AS total_trips,
  FORMAT('%.2f', AVG(fare))         AS avg_fare                 -- two‑decimal formatting
FROM filtered
GROUP BY decile
ORDER BY MIN(duration_min);