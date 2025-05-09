-- Companies with the three biggest jumps in trip counts between any two
-- consecutive months during 2018
WITH monthly_counts AS (
  SELECT
    company,
    DATE_TRUNC(trip_start_timestamp, MONTH) AS month_start,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
  GROUP BY company, month_start
),
month_diffs AS (
  SELECT
    company,
    month_start,
    trips,
    LAG(trips) OVER (PARTITION BY company ORDER BY month_start) AS prev_trips,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month_start) AS trip_change
  FROM monthly_counts
),
max_increase AS (
  SELECT
    company,
    MAX(trip_change) AS max_monthly_increase
  FROM month_diffs
  WHERE trip_change IS NOT NULL                   -- exclude first month per company
  GROUP BY company
)
SELECT
  company,
  max_monthly_increase AS trip_increase
FROM max_increase
ORDER BY max_monthly_increase DESC
LIMIT 3;