WITH
  companies AS (
    SELECT DISTINCT company
    FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
  ),
  months AS (
    SELECT month_num
    FROM UNNEST(GENERATE_ARRAY(1, 12)) AS month_num
  ),
  company_months AS (
    SELECT company, month_num AS month
    FROM companies
    CROSS JOIN months
  ),
  monthly_trip_counts AS (
    SELECT
      company,
      EXTRACT(MONTH FROM trip_start_timestamp) AS month,
      COUNT(*) AS trip_count
    FROM `bigquery-public-data.chicago_taxi_trips.taxi_trips`
    WHERE EXTRACT(YEAR FROM trip_start_timestamp) = 2018
    GROUP BY company, month
  ),
  full_monthly_data AS (
    SELECT
      cm.company,
      cm.month,
      IFNULL(mtc.trip_count, 0) AS trip_count
    FROM company_months cm
    LEFT JOIN monthly_trip_counts mtc
      ON cm.company = mtc.company AND cm.month = mtc.month
  ),
  trip_differences AS (
    SELECT
      company,
      LAG(month) OVER (PARTITION BY company ORDER BY month) AS from_month,
      month AS to_month,
      LAG(trip_count) OVER (PARTITION BY company ORDER BY month) AS previous_trip_count,
      trip_count,
      trip_count - LAG(trip_count) OVER (PARTITION BY company ORDER BY month) AS trip_increase
    FROM full_monthly_data
  )
SELECT
  company,
  from_month AS From_Month,
  to_month AS To_Month,
  trip_increase AS Trip_Increase
FROM trip_differences
WHERE from_month IS NOT NULL
ORDER BY trip_increase DESC
LIMIT 3;