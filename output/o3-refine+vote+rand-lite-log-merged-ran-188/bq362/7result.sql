-- 3 companies with the biggest jump in number of trips between any two consecutive
-- months during calendar‑year 2018
WITH monthly_counts AS (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month_num,
    COUNT(*) AS trips_in_month
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR  FROM trip_start_timestamp) = 2018        -- only 2018
    AND company IS NOT NULL                                    -- ignore missing company names
  GROUP BY company, month_num
),
month_over_month AS (
  SELECT
    company,
    month_num,
    trips_in_month,
    LAG(trips_in_month) OVER (PARTITION BY company ORDER BY month_num) AS prev_month_trips,
    trips_in_month - LAG(trips_in_month) OVER (PARTITION BY company ORDER BY month_num) AS trip_change
  FROM monthly_counts
),
best_jump_per_company AS (
  SELECT
    company,
    MAX(trip_change) AS max_monthly_increase          -- biggest positive jump for that company
  FROM month_over_month
  WHERE trip_change > 0                               -- keep only increases
  GROUP BY company
)
SELECT
  company,
  max_monthly_increase
FROM best_jump_per_company
ORDER BY max_monthly_increase DESC, company
LIMIT 3;