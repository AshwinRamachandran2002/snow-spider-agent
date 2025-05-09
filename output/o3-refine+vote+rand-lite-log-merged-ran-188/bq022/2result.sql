-- Six-quantile summary of Chicago taxi trips lasting 0–60 minutes
SELECT
  quantile                                   AS duration_quantile,
  MIN(ROUND(trip_seconds / 60.0)) AS min_trip_minutes,
  MAX(ROUND(trip_seconds / 60.0)) AS max_trip_minutes,
  COUNT(*)                           AS total_trips,
  AVG(fare)                          AS avg_fare
FROM (
  SELECT
    NTILE(6) OVER (ORDER BY `trip_seconds`) AS quantile,
    `trip_seconds`,
    `fare`
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE `trip_seconds` BETWEEN 0 AND 3600          -- only trips 0–60 minutes
)
GROUP BY quantile
ORDER BY quantile;