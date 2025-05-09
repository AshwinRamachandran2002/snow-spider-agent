WITH durations AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS rounded_minutes,
    fare,
    NTILE(10) OVER (ORDER BY ROUND(trip_seconds / 60.0)) AS decile
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
),
aggregated AS (
  SELECT
    decile,
    MIN(rounded_minutes) AS min_min,
    MAX(rounded_minutes) AS max_min,
    COUNT(*)            AS total_trips,
    AVG(fare)           AS avg_fare
  FROM durations
  GROUP BY decile
)
SELECT
  CONCAT(
    LPAD(CAST(min_min AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(max_min AS STRING), 2, '0'), 'm'
  )                           AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare)    AS average_fare
FROM aggregated
ORDER BY min_min;