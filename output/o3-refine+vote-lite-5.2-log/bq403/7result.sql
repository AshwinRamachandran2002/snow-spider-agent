WITH all_filings AS (
  -- Bring each year’s table to a common schema (all numbers cast to the same type)
  SELECT SAFE_CAST(tax_pd AS INT64) AS tax_pd_int,
         SAFE_CAST(totrevenue     AS FLOAT64) AS totrevenue,
         SAFE_CAST(totfuncexpns  AS FLOAT64) AS totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  UNION ALL
  SELECT SAFE_CAST(tax_pd AS INT64), SAFE_CAST(totrevenue AS FLOAT64), SAFE_CAST(totfuncexpns AS FLOAT64)
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  UNION ALL
  SELECT SAFE_CAST(tax_pd AS INT64), SAFE_CAST(totrevenue AS FLOAT64), SAFE_CAST(totfuncexpns AS FLOAT64)
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  UNION ALL
  SELECT SAFE_CAST(tax_pd AS INT64), SAFE_CAST(totrevenue AS FLOAT64), SAFE_CAST(totfuncexpns AS FLOAT64)
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  UNION ALL
  SELECT SAFE_CAST(tax_pd AS INT64), SAFE_CAST(totrevenue AS FLOAT64), SAFE_CAST(totfuncexpns AS FLOAT64)
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  UNION ALL
  SELECT SAFE_CAST(tax_pd AS INT64), SAFE_CAST(totrevenue AS FLOAT64), SAFE_CAST(totfuncexpns AS FLOAT64)
  FROM `bigquery-public-data.irs_990.irs_990_2017`
),
filtered AS (
  SELECT
    CAST(FLOOR(tax_pd_int / 100) AS INT64) AS year,  -- convert YYYYMM to YYYY
    totrevenue,
    totfuncexpns
  FROM all_filings
  WHERE tax_pd_int IS NOT NULL
    AND totrevenue   IS NOT NULL
    AND totfuncexpns IS NOT NULL
),
year_medians AS (
  SELECT
    year,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)] AS median_expenses
  FROM filtered
  GROUP BY year
)
SELECT
  year,
  ABS(median_revenue - median_expenses) AS median_diff
FROM year_medians
WHERE year BETWEEN 2012 AND 2017
ORDER BY median_diff ASC, year
LIMIT 3;