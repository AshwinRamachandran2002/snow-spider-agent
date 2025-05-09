WITH months AS (
  SELECT m AS month
  FROM UNNEST(GENERATE_ARRAY(1, 12)) AS m
),
companies AS (
  SELECT DISTINCT company
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
),
month_counts AS (
  SELECT
    c.company,
    m.month,
    COUNT(t.unique_key) AS trips
  FROM companies c
  CROSS JOIN months m
  LEFT JOIN `bigquery-public-data.chicago_taxi_trips.taxi_trips` t
    ON t.company = c.company
    AND EXTRACT(YEAR FROM t.trip_start_timestamp) = 2018
    AND EXTRACT(MONTH FROM t.trip_start_timestamp) = m.month
  GROUP BY c.company, m.month
),
deltas AS (
  SELECT
    company,
    month,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS mom_increase
  FROM month_counts
)
SELECT
  company,
  MAX(mom_increase) AS trip_increase
FROM deltas
WHERE mom_increase > 0
GROUP BY company
ORDER BY trip_increase DESC, company
LIMIT 3;