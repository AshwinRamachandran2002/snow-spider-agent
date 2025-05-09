WITH base AS (
  -- Keep only trips 1–50 minutes long and compute rounded minute duration
  SELECT
    CAST(ROUND(trip_seconds/60.0) AS INT64) AS duration_min,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 60 AND 3000          -- 1-50 minutes
),
quantiles AS (
  -- Build 10 equal-sized quantile buckets on the rounded duration
  SELECT
    duration_min,
    fare,
    NTILE(10) OVER (ORDER BY duration_min) AS decile
  FROM base
),
agg AS (
  -- Aggregate stats per quantile
  SELECT
    decile,
    MIN(duration_min) AS min_dur,
    MAX(duration_min) AS max_dur,
    COUNT(*)          AS total_trips,
    AVG(fare)         AS avg_fare
  FROM quantiles
  GROUP BY decile
)
-- Format final output
SELECT
  CONCAT(
    LPAD(CAST(min_dur AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(max_dur AS STRING), 2, '0'), 'm'
  )                          AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare)   AS avg_fare
FROM agg
ORDER BY min_dur;