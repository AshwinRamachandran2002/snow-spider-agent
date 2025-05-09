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
    trips - LAG(trips) OVER (PARTITION BY `company` ORDER BY month) AS diff
  FROM monthly
),
max_diff AS (
  SELECT
    `company`,
    MAX(diff) AS max_monthly_increase
  FROM diffs
  GROUP BY `company`
  HAVING max_monthly_increase IS NOT NULL
)
SELECT
  `company`,
  max_monthly_increase
FROM max_diff
ORDER BY max_monthly_increase DESC
LIMIT 3;