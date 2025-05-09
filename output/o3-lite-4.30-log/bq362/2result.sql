WITH months AS (
  SELECT m AS month
  FROM UNNEST(GENERATE_ARRAY(1, 12)) AS m
),
companies AS (
  SELECT DISTINCT company
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
),
company_month_grid AS (
  SELECT c.company, m.month
  FROM companies AS c
  CROSS JOIN months AS m
),
monthly_trip_counts AS (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month,
    COUNT(*) AS trips
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
  GROUP BY company, month
),
complete_monthly_counts AS (
  SELECT
    g.company,
    g.month,
    IFNULL(t.trips, 0) AS trips
  FROM company_month_grid AS g
  LEFT JOIN monthly_trip_counts AS t
  USING (company, month)
),
month_deltas AS (
  SELECT
    company,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS trip_increase
  FROM complete_monthly_counts
)
SELECT
  company,
  MAX(trip_increase) AS trip_increase
FROM month_deltas
WHERE trip_increase IS NOT NULL
GROUP BY company
ORDER BY trip_increase DESC, company
LIMIT 3;