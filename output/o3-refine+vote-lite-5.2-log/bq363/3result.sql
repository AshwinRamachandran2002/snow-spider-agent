WITH filtered AS (
  -- Keep trips whose rounded duration is between 1 and 50 minutes (inclusive)
  SELECT
    ROUND(trip_seconds / 60.0) AS duration_min,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
),
binned AS (
  -- Create ten equal‑sized quantile groups on the rounded duration
  SELECT
    duration_min,
    fare,
    NTILE(10) OVER (ORDER BY duration_min) AS decile
  FROM filtered
  WHERE duration_min BETWEEN 1 AND 50
)
SELECT
  -- Zero‑padded time range label for each quantile
  CONCAT(
    LPAD(CAST(MIN(duration_min) AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(MAX(duration_min) AS STRING), 2, '0'), 'm'
  )            AS time_range,
  COUNT(*)      AS total_trips,
  FORMAT('%.2f', AVG(fare)) AS average_fare
FROM binned
GROUP BY decile
ORDER BY decile;