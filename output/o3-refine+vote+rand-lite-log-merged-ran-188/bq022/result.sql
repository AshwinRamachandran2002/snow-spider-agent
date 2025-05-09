-- Min & max duration, trip count, and average fare for six equal-duration quantiles (0–60-minute trips)
SELECT
  tile AS duration_quantile,
  ROUND(MIN(trip_seconds) / 60.0) AS min_minutes,
  ROUND(MAX(trip_seconds) / 60.0) AS max_minutes,
  COUNT(*)                       AS total_trips,
  ROUND(AVG(fare), 2)            AS avg_fare
FROM (
  SELECT
    NTILE(6) OVER (ORDER BY trip_seconds) AS tile,
    trip_seconds,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0              -- positive duration
    AND trip_seconds <= 60 * 60       -- up to 60 minutes
) AS t
GROUP BY tile
ORDER BY tile;