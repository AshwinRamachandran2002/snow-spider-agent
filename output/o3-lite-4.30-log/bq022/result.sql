SELECT
  min_trip_duration,
  max_trip_duration,
  total_trips,
  avg_fare
FROM (
  SELECT
    duration_bucket,
    MIN(CAST(ROUND(trip_seconds / 60.0) AS INT64)) AS min_trip_duration,
    MAX(CAST(ROUND(trip_seconds / 60.0) AS INT64)) AS max_trip_duration,
    COUNT(*)                                        AS total_trips,
    ROUND(AVG(fare), 4)                             AS avg_fare
  FROM (
    SELECT
      trip_seconds,
      fare,
      NTILE(6) OVER (ORDER BY trip_seconds) AS duration_bucket
    FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE trip_seconds > 0
      AND trip_seconds <= 60 * 60
  )
  GROUP BY duration_bucket
)
ORDER BY min_trip_duration;