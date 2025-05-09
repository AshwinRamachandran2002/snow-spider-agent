WITH base AS (
  SELECT
    CAST(ROUND(`trip_seconds` / 60.0) AS INT64) AS duration_min,
    `fare`
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE `trip_seconds` IS NOT NULL
    AND CAST(ROUND(`trip_seconds` / 60.0) AS INT64) BETWEEN 1 AND 50
),
q AS (
  SELECT
    duration_min,
    fare,
    NTILE(10) OVER (ORDER BY duration_min) AS tile
  FROM base
)
SELECT
  FORMAT('%02dm to %02dm',
         MIN(duration_min),
         MAX(duration_min))       AS time_range,
  COUNT(*)                       AS total_trips,
  FORMAT('%.2f', AVG(fare))      AS avg_fare
FROM q
GROUP BY tile
ORDER BY MIN(duration_min);