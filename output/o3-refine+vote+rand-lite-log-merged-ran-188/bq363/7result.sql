WITH trips AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds IS NOT NULL
    AND fare IS NOT NULL
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
),
bucketed AS (
  SELECT
    NTILE(10) OVER (ORDER BY trip_minutes) AS quantile,
    trip_minutes,
    fare
  FROM trips
),
agg AS (
  SELECT
    quantile,
    MIN(trip_minutes) AS min_minute,
    MAX(trip_minutes) AS max_minute,
    COUNT(*)          AS total_trips,
    AVG(fare)         AS avg_fare
  FROM bucketed
  GROUP BY quantile
)
SELECT
  CONCAT(
    LPAD(CAST(min_minute AS STRING), 2, '0'), 'm to ',
    LPAD(CAST(max_minute AS STRING), 2, '0'), 'm'
  ) AS time_range,
  total_trips,
  FORMAT('%.2f', avg_fare) AS avg_fare
FROM agg
ORDER BY min_minute;