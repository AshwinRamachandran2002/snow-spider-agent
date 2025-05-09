WITH all_data AS (
  SELECT '2012' AS year, totrevenue AS revenue, totfuncexpns AS expenses
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  UNION ALL
  SELECT '2013', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  UNION ALL
  SELECT '2014', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  UNION ALL
  SELECT '2015', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  UNION ALL
  SELECT '2016', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  UNION ALL
  SELECT '2017', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`
),
filtered AS (
  SELECT year, revenue, expenses
  FROM all_data
  WHERE revenue IS NOT NULL
    AND expenses IS NOT NULL
),
median_vals AS (
  SELECT
    year,
    APPROX_QUANTILES(revenue, 2)[OFFSET(1)]  AS median_revenue,
    APPROX_QUANTILES(expenses, 2)[OFFSET(1)] AS median_expenses
  FROM filtered
  GROUP BY year
)
SELECT
  year,
  ROUND(ABS(median_revenue - median_expenses), 4) AS absolute_difference
FROM median_vals
ORDER BY absolute_difference
LIMIT 3;