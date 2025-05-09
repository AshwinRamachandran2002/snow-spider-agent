WITH monthly AS (
  SELECT
    company,
    DATE_TRUNC(DATE(trip_start_timestamp), MONTH) AS month_start,
    COUNT(*) AS trips
  FROM
    `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE
    EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
  GROUP BY
    company,
    month_start
),
mom_changes AS (
  SELECT
    company,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month_start) AS mom_change
  FROM
    monthly
)
SELECT
  company,
  MAX(mom_change) AS largest_monthly_increase_2018
FROM
  mom_changes
GROUP BY
  company
ORDER BY
  largest_monthly_increase_2018 DESC
LIMIT 3;