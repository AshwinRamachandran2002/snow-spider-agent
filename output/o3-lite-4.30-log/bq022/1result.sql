WITH filtered AS (
  SELECT
    trip_seconds,
    fare
  FROM
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds > 0
    AND trip_seconds <= 3600                              -- 0–60‑minute trips
),
ranked AS (
  SELECT
    trip_seconds,
    fare,
    NTILE(6) OVER (ORDER BY trip_seconds) AS duration_quantile
  FROM
    filtered
)
SELECT
  MIN(ROUND(trip_seconds / 60.0)) AS min_trip_duration,
  MAX(ROUND(trip_seconds / 60.0)) AS max_trip_duration,
  COUNT(*)                        AS total_trips,
  ROUND(AVG(fare), 4)             AS avg_fare
FROM
  ranked
GROUP BY
  duration_quantile
ORDER BY
  min_trip_duration;