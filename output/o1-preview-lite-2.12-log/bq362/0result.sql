SELECT
  t1.company AS Company,
  CAST(t1.month AS STRING) AS From_Month,
  CAST(t2.month AS STRING) AS To_Month,
  t2.trip_count - t1.trip_count AS Trip_Increase
FROM (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(unique_key) AS trip_count
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
  GROUP BY company, month
) t1
JOIN (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(unique_key) AS trip_count
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
  GROUP BY company, month
) t2
ON t1.company = t2.company AND t2.month = t1.month + 1
ORDER BY Trip_Increase DESC
LIMIT 3;