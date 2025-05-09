WITH filtered AS (
  SELECT
    CAST(ROUND(trip_seconds / 60.0) AS INT64) AS minutes,   -- rounded trip duration in minutes
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50         -- keep trips 1‑50 minutes long
), ranked AS (
  SELECT
    minutes,
    fare,
    NTILE(10) OVER (ORDER BY minutes) AS decile             -- create 10 equal‑sized quantiles
  FROM filtered
)
SELECT
  FORMAT('%02dm to %02dm', MIN(minutes), MAX(minutes)) AS time_range,
  COUNT(*)                                             AS total_trips,
  ROUND(AVG(fare), 2)                                  AS avg_fare
FROM ranked
GROUP BY decile
ORDER BY MIN(minutes);