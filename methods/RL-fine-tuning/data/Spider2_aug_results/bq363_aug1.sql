-- Task: Calculate the total number of trips and average fare (formatted to two decimal places) for each rounded trip duration between 1 and 50 minutes, displaying each duration and corresponding totals sorted chronologically.
SELECT
  ROUND(trip_seconds / 60) AS duration_in_minutes,
  COUNT(1) AS total_trips,
  FORMAT('%3.2f', AVG(fare)) AS average_fare
FROM
  `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE
  ROUND(trip_seconds / 60) BETWEEN 1 AND 50
GROUP BY
  duration_in_minutes
ORDER BY
  duration_in_minutes