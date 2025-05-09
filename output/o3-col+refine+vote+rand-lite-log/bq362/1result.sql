-- Which three companies had the largest increase in trip numbers
-- between any two consecutive months in 2018?
WITH monthly AS (
  SELECT
    `company`,
    EXTRACT(MONTH FROM `trip_start_timestamp`) AS month,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM `trip_start_timestamp`) = 2018
    AND `company` IS NOT NULL
  GROUP BY `company`, month
),
diffs AS (
  SELECT
    `company`,
    month,
    trips - LAG(trips) OVER (PARTITION BY `company` ORDER BY month) AS mom_change
  FROM monthly
)
SELECT
  `company`,
  MAX(mom_change) AS largest_monthly_increase_in_2018
FROM diffs
WHERE mom_change IS NOT NULL
GROUP BY `company`
ORDER BY largest_monthly_increase_in_2018 DESC
LIMIT 3;