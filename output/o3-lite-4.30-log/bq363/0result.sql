WITH filtered AS (
  SELECT
    fare,
    CAST(ROUND(trip_seconds / 60.0) AS INT64) AS trip_minutes
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
),
quantiles AS (
  SELECT
    fare,
    trip_minutes,
    NTILE(10) OVER (ORDER BY trip_minutes) AS quantile
  FROM filtered
)
SELECT
  CONCAT(
    LPAD(CAST(MIN(trip_minutes) AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(MAX(trip_minutes) AS STRING), 2, '0'), 'm'
  ) AS time_range,
  COUNT(*) AS total_trips,
  FORMAT('%.2f', AVG(fare)) AS average_fare
FROM quantiles
GROUP BY quantile
ORDER BY MIN(trip_minutes), MAX(trip_minutes);