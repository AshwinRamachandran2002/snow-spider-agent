WITH trips_2018 AS (
  SELECT
    company,
    EXTRACT(MONTH FROM trip_start_timestamp) AS month
  FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
  WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    AND company IS NOT NULL
    AND company <> ''
),
companies AS (
  SELECT DISTINCT company FROM trips_2018
),
calendar AS (
  SELECT month FROM UNNEST(GENERATE_ARRAY(1, 12)) AS month
),
month_counts AS (
  SELECT
    c.company,
    cal.month,
    COUNT(t.month) AS trips
  FROM companies c
  CROSS JOIN calendar cal
  LEFT JOIN trips_2018 t
    ON t.company = c.company
    AND t.month = cal.month
  GROUP BY c.company, cal.month
),
diffs AS (
  SELECT
    company,
    trips - LAG(trips) OVER (PARTITION BY company ORDER BY month) AS diff
  FROM month_counts
),
best_increase AS (
  SELECT
    company,
    MAX(diff) AS trip_increase
  FROM diffs
  WHERE diff IS NOT NULL
  GROUP BY company
)
SELECT
  company,
  trip_increase
FROM best_increase
ORDER BY trip_increase DESC, company
LIMIT 3;