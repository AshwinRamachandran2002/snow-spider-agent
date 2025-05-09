WITH eligible AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS rounded_minutes,
    fare
  FROM
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds IS NOT NULL
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
),
quant AS (
  SELECT
    NTILE(10) OVER (ORDER BY rounded_minutes) AS qtile,
    rounded_minutes,
    fare
  FROM eligible
),
summary AS (
  SELECT
    qtile,
    MIN(rounded_minutes) AS min_min,
    MAX(rounded_minutes) AS max_min,
    COUNT(*)            AS total_trips,
    AVG(fare)           AS avg_fare
  FROM quant
  GROUP BY qtile
)
SELECT
  CONCAT(
    LPAD(CAST(min_min AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(max_min AS STRING), 2, '0'), 'm'
  )           AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare) AS avg_fare
FROM summary
ORDER BY min_min;