/* Three years (2012‑2017) with the smallest absolute gap between
   median total revenue and median functional expenses                  */
WITH data AS (
  SELECT * FROM (
    SELECT 2012 AS year,
           SAFE_CAST(totrevenue   AS INT64) AS revenue,
           SAFE_CAST(totfuncexpns AS INT64) AS expense
    FROM `bigquery-public-data.irs_990.irs_990_2012`
    UNION ALL
    SELECT 2013, SAFE_CAST(totrevenue AS INT64), SAFE_CAST(totfuncexpns AS INT64)
    FROM `bigquery-public-data.irs_990.irs_990_2013`
    UNION ALL
    SELECT 2014, SAFE_CAST(totrevenue AS INT64), SAFE_CAST(totfuncexpns AS INT64)
    FROM `bigquery-public-data.irs_990.irs_990_2014`
    UNION ALL
    SELECT 2015, SAFE_CAST(totrevenue AS INT64), SAFE_CAST(totfuncexpns AS INT64)
    FROM `bigquery-public-data.irs_990.irs_990_2015`
    UNION ALL
    SELECT 2016, SAFE_CAST(totrevenue AS INT64), SAFE_CAST(totfuncexpns AS INT64)
    FROM `bigquery-public-data.irs_990.irs_990_2016`
    UNION ALL
    SELECT 2017, SAFE_CAST(totrevenue AS INT64), SAFE_CAST(totfuncexpns AS INT64)
    FROM `bigquery-public-data.irs_990.irs_990_2017`
  )
  WHERE revenue IS NOT NULL
    AND expense IS NOT NULL
),
medians AS (
  SELECT
    year,
    APPROX_QUANTILES(revenue, 2)[OFFSET(1)]  AS median_revenue,
    APPROX_QUANTILES(expense, 2)[OFFSET(1)]  AS median_expense
  FROM data
  GROUP BY year
),
diffs AS (
  SELECT
    year,
    ABS(median_revenue - median_expense) AS absolute_difference
  FROM medians
)
SELECT
  year,
  absolute_difference
FROM diffs
ORDER BY absolute_difference, year
LIMIT 3;