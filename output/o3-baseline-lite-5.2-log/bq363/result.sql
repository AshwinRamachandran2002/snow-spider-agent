WITH base AS (
  SELECT
    unique_key,
    ROUND(trip_seconds / 60.0) AS duration_min,   -- round duration to nearest minute
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
),
filtered AS (
  -- keep only trips 1‑50 minutes long
  SELECT *
  FROM base
  WHERE duration_min BETWEEN 1 AND 50
),
tiles AS (
  -- divide the trips into 10 equal‑sized quantile groups
  SELECT
    *,
    NTILE(10) OVER (ORDER BY duration_min) AS quantile
  FROM filtered
),
agg AS (
  -- aggregate per quantile
  SELECT
    quantile,
    MIN(duration_min) AS min_dur,
    MAX(duration_min) AS max_dur,
    COUNT(*)           AS trip_count,
    AVG(fare)          AS avg_fare
  FROM tiles
  GROUP BY quantile
)
SELECT
  CONCAT(
    LPAD(CAST(min_dur AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(max_dur AS STRING), 2, '0'), 'm'
  ) AS time_range,
  trip_count,
  FORMAT('%.2f', avg_fare) AS average_fare
FROM agg
ORDER BY min_dur;