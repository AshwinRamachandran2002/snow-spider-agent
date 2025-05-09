WITH base AS (
  SELECT
    CAST(ROUND(trip_seconds / 60.0) AS INT64) AS duration_min,  -- rounded minutes as INT64
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare          IS NOT NULL
    AND trip_seconds  > 0
),
filtered AS (                              -- keep trips 1–50 minutes long
  SELECT *
  FROM base
  WHERE duration_min BETWEEN 1 AND 50
),
tiles AS (                                 -- create ten equal‑sized quantiles
  SELECT
    duration_min,
    fare,
    NTILE(10) OVER (ORDER BY duration_min) AS q
  FROM filtered
)
SELECT
  FORMAT(
    "%02dm to %02dm",
    CAST(MIN(duration_min) AS INT64),
    CAST(MAX(duration_min) AS INT64)
  ) AS time_range,
  COUNT(*)        AS total_trips,
  ROUND(AVG(fare), 2) AS avg_fare
FROM tiles
GROUP BY q
ORDER BY MIN(duration_min);