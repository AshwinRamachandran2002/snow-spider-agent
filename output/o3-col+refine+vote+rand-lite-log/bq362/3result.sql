WITH monthly AS (
  SELECT
    `company`,
    EXTRACT(MONTH FROM `trip_start_timestamp`) AS month,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM `trip_start_timestamp`) = 2018
  GROUP BY `company`, month
),
diffs AS (
  SELECT
    `company`,
    month,
    trips,
    trips - LAG(trips) OVER (PARTITION BY `company` ORDER BY month) AS diff
  FROM monthly
),
max_increase AS (
  SELECT
    `company`,
    MAX(diff) AS largest_monthly_increase
  FROM diffs
  GROUP BY `company`
)
SELECT
  `company`,
  largest_monthly_increase
FROM max_increase
ORDER BY largest_monthly_increase DESC
LIMIT 3;