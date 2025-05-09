-- 3 companies with the greatest month‑over‑month jump in trip counts in 2018
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
month_diffs AS (
  SELECT
    company,
    month,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS trip_increase
  FROM month_counts
)
SELECT
  company
FROM (
  SELECT
    company,
    MAX(trip_increase) AS max_monthly_increase
  FROM month_diffs
  WHERE trip_increase IS NOT NULL AND trip_increase > 0
  GROUP BY company
)
ORDER BY max_monthly_increase DESC
LIMIT 3;