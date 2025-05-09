WITH durations AS (
  SELECT
    CAST(ROUND(trip_seconds / 60.0) AS INT64) AS duration_min,  -- ensure INT64
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
),
bounded AS (
  SELECT *
  FROM durations
  WHERE duration_min BETWEEN 1 AND 50                            -- 1‑50 minute trips
),
tiles AS (
  SELECT
    *,
    NTILE(10) OVER (ORDER BY duration_min) AS decile             -- 10 equal‑sized quantiles
  FROM bounded
),
agg AS (
  SELECT
    decile,
    MIN(duration_min) AS min_dur,
    MAX(duration_min) AS max_dur,
    COUNT(*)          AS total_trips,
    AVG(fare)         AS avg_fare
  FROM tiles
  GROUP BY decile
)
SELECT
  FORMAT('%02dm to %02dm', CAST(min_dur AS INT64), CAST(max_dur AS INT64)) AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare) AS avg_fare
FROM agg
ORDER BY min_dur;