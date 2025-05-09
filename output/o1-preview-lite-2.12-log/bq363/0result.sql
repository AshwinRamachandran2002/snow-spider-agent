WITH filtered_trips AS (
  SELECT 
    ROUND(trip_seconds / 60.0) AS trip_minutes,
    trip_total AS fare
  FROM 
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds IS NOT NULL 
    AND trip_seconds > 0
    AND trip_total IS NOT NULL 
    AND trip_total > 0
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
),
quantiles AS (
  SELECT
    trip_minutes,
    fare,
    NTILE(10) OVER (ORDER BY trip_minutes) AS quantile_group
  FROM
    filtered_trips
),
aggregated AS (
  SELECT
    quantile_group,
    MIN(trip_minutes) AS min_minutes,
    MAX(trip_minutes) AS max_minutes,
    COUNT(*) AS total_trips,
    ROUND(AVG(fare), 2) AS average_fare
  FROM
    quantiles
  GROUP BY
    quantile_group
)
SELECT
  CONCAT(LPAD(CAST(min_minutes AS STRING), 2, '0'), 'm to ', LPAD(CAST(max_minutes AS STRING), 2, '0'), 'm') AS Time_range,
  total_trips,
  average_fare
FROM
  aggregated
ORDER BY
  min_minutes;