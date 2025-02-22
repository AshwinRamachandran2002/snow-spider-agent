-- Task: Assign quantile groups (from 1 to 6) to each trip based on trip duration, considering only trips between 0 and 60 minutes, and show the first 100 results.
SELECT
  trip_seconds,
  NTILE(6) OVER (ORDER BY trip_seconds) AS quantile,
  fare
FROM
  `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE
  trip_seconds BETWEEN 0 AND 3600
LIMIT 100