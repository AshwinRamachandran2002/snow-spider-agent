/* Which three companies had the largest increase in trip numbers
   between two consecutive months in 2018? */

WITH month_counts AS (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
  GROUP BY company, month
),
diffs AS (
  SELECT
    company,
    month,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS diff
  FROM month_counts
),
max_increase AS (
  SELECT
    company,
    MAX(diff) AS largest_monthly_increase
  FROM diffs
  WHERE diff IS NOT NULL AND diff > 0
  GROUP BY company
)
SELECT
  company,
  largest_monthly_increase
FROM max_increase
ORDER BY largest_monthly_increase DESC
LIMIT 3;