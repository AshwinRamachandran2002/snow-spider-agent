WITH durations AS (
  -- Keep trips whose rounded duration is between 1 and 50 minutes
  SELECT
    CAST(ROUND(trip_seconds / 60.0) AS INT64) AS duration_min,  -- ensure INT64
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
),
quantiled AS (
  -- Assign each trip to one of ten equal‑sized quantiles
  SELECT
    NTILE(10) OVER (ORDER BY duration_min) AS qtile,
    duration_min,
    fare
  FROM durations
  WHERE duration_min BETWEEN 1 AND 50
)
SELECT
  FORMAT('%02dm to %02dm', MIN(duration_min), MAX(duration_min)) AS time_range,
  COUNT(*)                                                       AS total_trips,
  FORMAT('%.2f', AVG(fare))                                      AS avg_fare
FROM quantiled
GROUP BY qtile
ORDER BY MIN(duration_min);