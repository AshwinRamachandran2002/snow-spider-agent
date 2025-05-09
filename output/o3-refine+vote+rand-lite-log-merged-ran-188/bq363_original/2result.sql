WITH filtered AS (
  -- Keep trips with reasonable, numeric duration (rounded 1‑50 minutes) and a recorded fare
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
),
limited AS (
  -- Limit to the requested 1‑50 minute range
  SELECT *
  FROM filtered
  WHERE trip_minutes BETWEEN 1 AND 50
),
quantiled AS (
  -- Create ten equal‑sized quantiles on the rounded duration
  SELECT
    *,
    NTILE(10) OVER (ORDER BY trip_minutes) AS quantile
  FROM limited
),
aggregated AS (
  -- Aggregate the required metrics per quantile
  SELECT
    quantile,
    MIN(trip_minutes) AS min_minute,
    MAX(trip_minutes) AS max_minute,
    COUNT(*)           AS total_trips,
    AVG(fare)          AS avg_fare
  FROM quantiled
  GROUP BY quantile
)
-- Final, formatted result
SELECT
  CONCAT(LPAD(CAST(min_minute AS STRING), 2, '0'), 'm to ',
         LPAD(CAST(max_minute AS STRING), 2, '0'), 'm') AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare) AS average_fare
FROM aggregated
ORDER BY min_minute;