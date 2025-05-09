WITH monthly_counts AS (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(*) AS trip_cnt
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
  GROUP BY company, month
),
month_diffs AS (
  SELECT
    company,
    month,
    trip_cnt - LAG(trip_cnt) OVER (PARTITION BY company ORDER BY month) AS diff_from_prev_month
  FROM monthly_counts
)
SELECT
  company,
  MAX(diff_from_prev_month) AS max_increase
FROM month_diffs
WHERE diff_from_prev_month > 0
GROUP BY company
ORDER BY max_increase DESC
LIMIT 3;