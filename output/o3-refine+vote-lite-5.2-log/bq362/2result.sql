WITH monthly_counts AS (
  SELECT
    company,
    DATE_TRUNC(trip_start_timestamp, MONTH) AS month,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
  GROUP BY company, month
),
with_prev AS (
  SELECT
    company,
    month,
    trips,
    LAG(trips) OVER (PARTITION BY company ORDER BY month) AS prev_trips
  FROM monthly_counts
),
increases AS (
  SELECT
    company,
    trips - prev_trips AS increase
  FROM with_prev
  WHERE prev_trips IS NOT NULL
)
SELECT
  company,
  MAX(increase) AS max_monthly_increase
FROM increases
GROUP BY company
ORDER BY max_monthly_increase DESC
LIMIT 3;