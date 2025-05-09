WITH trips AS (
  SELECT
    ROUND(trip_seconds / 60.0) AS trip_minutes,
    fare
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_seconds > 0
    AND fare > 0
    AND ROUND(trip_seconds / 60.0) BETWEEN 1 AND 50
),
trip_groups AS (
  SELECT
    trip_minutes,
    fare,
    NTILE(10) OVER (ORDER BY trip_minutes) AS quantile_group
  FROM trips
)
SELECT
  CONCAT(CAST(MIN(trip_minutes) AS STRING), 'm to ', CAST(MAX(trip_minutes) AS STRING), 'm') AS Time_range,
  COUNT(*) AS Total_trips,
  ROUND(AVG(fare), 2) AS Average_fare
FROM trip_groups
GROUP BY quantile_group
ORDER BY MIN(trip_minutes);