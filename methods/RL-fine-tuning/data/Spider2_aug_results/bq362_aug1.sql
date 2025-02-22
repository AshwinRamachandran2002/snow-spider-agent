-- Task: Which three companies had the highest number of trips in 2018?
SELECT
  company,
  COUNT(*) AS trip_count
FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
GROUP BY company
ORDER BY trip_count DESC
LIMIT 3;