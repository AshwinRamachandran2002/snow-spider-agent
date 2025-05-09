WITH monthly_trips AS (
  -- trip counts for every company by month in 2018
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(*) AS trip_cnt
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
  GROUP BY company, month
),
month_over_month AS (
  -- month‑over‑month change in trip counts for each company
  SELECT
    company,
    month,
    trip_cnt,
    trip_cnt - IFNULL(LAG(trip_cnt) OVER (PARTITION BY company ORDER BY month), 0) AS delta
  FROM monthly_trips
),
best_delta_per_company AS (
  -- largest positive jump each company experienced
  SELECT
    company,
    MAX(delta) AS max_monthly_increase
  FROM month_over_month
  GROUP BY company
)
-- top 3 companies with the biggest single‑month increases
SELECT
  company,
  max_monthly_increase
FROM best_delta_per_company
ORDER BY max_monthly_increase DESC, company
LIMIT 3;