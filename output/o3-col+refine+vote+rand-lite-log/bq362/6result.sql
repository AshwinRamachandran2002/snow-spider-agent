-- Three companies with the largest month-to-month trip count increase during 2018
WITH monthly_trips AS (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
  GROUP BY company, month
),
deltas AS (
  SELECT
    company,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS diff_from_prev
  FROM monthly_trips
),
max_increase AS (
  SELECT
    company,
    MAX(diff_from_prev) AS max_positive_increase
  FROM deltas
  GROUP BY company
)
SELECT
  company,
  max_positive_increase
FROM max_increase
ORDER BY max_positive_increase DESC
LIMIT 3;