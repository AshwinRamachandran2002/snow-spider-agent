WITH monthly_trips AS (
  -- Trip counts for every company by month in 2018
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
  -- Month‑to‑month changes per company
  SELECT
    company,
    month,
    trips,
    LAG(trips) OVER (PARTITION BY company ORDER BY month)            AS prev_trips,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month)    AS trip_increase
  FROM monthly_trips
),
max_increase_per_company AS (
  -- Largest single positive jump for each company
  SELECT
    company,
    MAX(trip_increase) AS max_monthly_increase
  FROM month_diffs
  GROUP BY company
)
-- Top three companies with the biggest month‑to‑month jump
SELECT
  company,
  max_monthly_increase
FROM max_increase_per_company
WHERE max_monthly_increase IS NOT NULL
ORDER BY max_monthly_increase DESC
LIMIT 3;