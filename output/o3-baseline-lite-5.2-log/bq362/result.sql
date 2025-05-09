-- Top three companies with the largest month‑over‑month increase in trip counts during 2018
WITH monthly_trips AS (
  SELECT
    company,
    DATE_TRUNC(trip_start_timestamp, MONTH) AS month,
    COUNT(*) AS trip_cnt
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
  GROUP BY company, month
),
month_diffs AS (
  SELECT
    company,
    month,
    trip_cnt
      - LAG(trip_cnt) OVER (PARTITION BY company ORDER BY month) AS diff
  FROM monthly_trips
),
max_positive_diff AS (
  SELECT
    company,
    MAX(diff) AS max_increase
  FROM month_diffs
  WHERE diff > 0            -- keep only positive increases
  GROUP BY company
)
SELECT
  company,
  max_increase AS trip_increase
FROM max_positive_diff
ORDER BY max_increase DESC, company
LIMIT 3;