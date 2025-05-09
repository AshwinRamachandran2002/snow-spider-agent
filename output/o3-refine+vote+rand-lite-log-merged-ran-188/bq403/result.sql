/* 3 calendar years (2012‑2017) whose medians of total revenue and
   total functional expenses are closest to one another               */
WITH filings AS (
  -- pull the needed columns from each year’s Form‑990 table
  SELECT 2012 AS year, totrevenue AS revenue, totfuncexpns AS expenses
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  WHERE totrevenue IS NOT NULL AND totfuncexpns IS NOT NULL
  UNION ALL
  SELECT 2013, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  WHERE totrevenue IS NOT NULL AND totfuncexpns IS NOT NULL
  UNION ALL
  SELECT 2014, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  WHERE totrevenue IS NOT NULL AND totfuncexpns IS NOT NULL
  UNION ALL
  SELECT 2015, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  WHERE totrevenue IS NOT NULL AND totfuncexpns IS NOT NULL
  UNION ALL
  SELECT 2016, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  WHERE totrevenue IS NOT NULL AND totfuncexpns IS NOT NULL
  UNION ALL
  SELECT 2017, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`
  WHERE totrevenue IS NOT NULL AND totfuncexpns IS NOT NULL
),
medians AS (
  SELECT
    year,
    APPROX_QUANTILES(revenue , 2)[OFFSET(1)] AS median_revenue,
    APPROX_QUANTILES(expenses, 2)[OFFSET(1)] AS median_expenses
  FROM filings
  GROUP BY year
)
SELECT
  year,
  ABS(median_revenue - median_expenses) AS difference
FROM medians
ORDER BY difference
LIMIT 3;