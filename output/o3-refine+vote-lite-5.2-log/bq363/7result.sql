WITH base AS (
  SELECT
    unique_key,
    -- Round trip duration to the nearest minute and cast to INT64
    CAST(ROUND(trip_seconds / 60.0) AS INT64) AS trip_min,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
),
filtered AS (
  SELECT *
  FROM base
  WHERE trip_min BETWEEN 1 AND 50
),
binned AS (
  SELECT
    *,
    NTILE(10) OVER (ORDER BY trip_min, unique_key) AS decile
  FROM filtered
),
agg AS (
  SELECT
    decile,
    MIN(trip_min) AS min_min,
    MAX(trip_min) AS max_min,
    COUNT(*)  AS total_trips,
    AVG(fare) AS avg_fare
  FROM binned
  GROUP BY decile
)
SELECT
  FORMAT('%02dm to %02dm', min_min, max_min) AS time_range,
  total_trips,
  ROUND(avg_fare, 2) AS average_fare
FROM agg
ORDER BY min_min;