-- Task: For all taxi trips with durations between 0 and 60 minutes (i.e., 0 to 3600 seconds), divide them into six equal-sized groups based on trip duration using NTILE(6). For each group, calculate the minimum and maximum trip durations in minutes (rounded to the nearest whole number), the total number of trips, and the average fare. Sort the results by the minimum and maximum trip durations.
SELECT
  ROUND(MIN(trip_seconds) / 60, 0) AS min_minutes,
  ROUND(MAX(trip_seconds) / 60, 0) AS max_minutes,
  COUNT(*) AS total_trips,
  AVG(fare) AS average_fare
FROM (
  SELECT
    trip_seconds,
    NTILE(6) OVER (ORDER BY trip_seconds) AS quantile,
    fare
  FROM
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    trip_seconds BETWEEN 0 AND 3600
)
GROUP BY
  quantile
ORDER BY
  min_minutes, max_minutes;