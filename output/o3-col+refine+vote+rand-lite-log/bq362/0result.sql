WITH monthly_trips AS (
  SELECT
    company,
    FORMAT_TIMESTAMP('%Y-%m', trip_start_timestamp) AS month,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE trip_start_timestamp BETWEEN '2018-01-01' AND '2018-12-31'
  GROUP BY company, month
),
deltas AS (
  SELECT
    company,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS diff
  FROM monthly_trips
),
max_jump AS (
  SELECT
    company,
    MAX(diff) AS largest_monthly_increase_2018
  FROM deltas
  GROUP BY company
)
SELECT
  company,
  largest_monthly_increase_2018
FROM max_jump
WHERE largest_monthly_increase_2018 IS NOT NULL
ORDER BY largest_monthly_increase_2018 DESC
LIMIT 3;