-- 3 companies with the biggest jump in trip counts between any two consecutive months of 2018
WITH companies AS (
  SELECT DISTINCT company
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR  FROM trip_start_timestamp) = 2018
        AND company IS NOT NULL
),
months AS (
  SELECT month_num
  FROM UNNEST(GENERATE_ARRAY(1,12)) AS month_num
),
-- create a full 12‑month grid for every 2018 company
company_month_grid AS (
  SELECT c.company, m.month_num AS month
  FROM companies c
  CROSS JOIN months m
),
-- trip totals per company per month (0 when none)
monthly_trips AS (
  SELECT
    g.company,
    g.month,
    COUNT(t.unique_key) AS trips
  FROM company_month_grid g
  LEFT JOIN `bigquery-public-data.chicago_taxi_trips.taxi_trips` t
    ON  t.company = g.company
    AND EXTRACT(YEAR  FROM t.trip_start_timestamp) = 2018
    AND EXTRACT(MONTH FROM t.trip_start_timestamp) = g.month
  GROUP BY g.company, g.month
),
-- month‑to‑month differences
deltas AS (
  SELECT
    company,
    month,
    trips,
    LAG(trips) OVER (PARTITION BY company ORDER BY month) AS prev_trips,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS diff
  FROM monthly_trips
),
-- greatest positive jump per company
max_jump AS (
  SELECT company, MAX(diff) AS max_increase
  FROM deltas
  GROUP BY company
)
SELECT company, max_increase
FROM   max_jump
WHERE  max_increase IS NOT NULL      -- exclude companies that never had a previous month
ORDER  BY max_increase DESC
LIMIT 3;