-- Ten-quantile summary of Chicago taxi trips (1–50-minute rides)
WITH duration_quantiles AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,        -- duration in whole minutes
    fare,
    NTILE(10) OVER (ORDER BY ROUND(trip_seconds / 60.0)) AS decile
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds BETWEEN 60 AND 3000               -- keep 1-50-minute trips
),
aggregated AS (
  SELECT
    decile,
    MIN(trip_minutes)               AS min_minutes,
    MAX(trip_minutes)               AS max_minutes,
    COUNT(*)                        AS total_trips,
    AVG(fare)                       AS avg_fare
  FROM duration_quantiles
  GROUP BY decile
)
SELECT
  CONCAT(
    LPAD(CAST(min_minutes AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(max_minutes AS STRING), 2, '0'), 'm'
  )                          AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare)   AS avg_fare
FROM aggregated
ORDER BY min_minutes;