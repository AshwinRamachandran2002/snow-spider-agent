WITH monthly_counts AS (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(*) AS trip_count
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
  GROUP BY company, month
),
monthly_diffs AS (
  SELECT
    company,
    trip_count - LAG(trip_count) OVER (PARTITION BY company ORDER BY month) AS diff
  FROM monthly_counts
),
max_increase AS (
  SELECT
    company,
    MAX(diff) AS max_monthly_increase
  FROM monthly_diffs
  WHERE diff > 0                     -- keep only positive jumps
  GROUP BY company
)
SELECT
  company,
  max_monthly_increase
FROM max_increase
ORDER BY max_monthly_increase DESC
LIMIT 3;