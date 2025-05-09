--  Three filing years (2012-2017) whose median revenues and
--  median functional expenses are closest to one another
WITH year_medians AS (
  -- ---- 2012 -------------------------------------------------------
  SELECT
    2012 AS filing_year,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  WHERE totrevenue IS NOT NULL
    AND totfuncexpns IS NOT NULL
  
  UNION ALL
  -- ---- 2013 -------------------------------------------------------
  SELECT
    2013,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)],
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  WHERE totrevenue IS NOT NULL
    AND totfuncexpns IS NOT NULL
  
  UNION ALL
  -- ---- 2014 -------------------------------------------------------
  SELECT
    2014,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)],
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  WHERE totrevenue IS NOT NULL
    AND totfuncexpns IS NOT NULL
  
  UNION ALL
  -- ---- 2015 -------------------------------------------------------
  SELECT
    2015,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)],
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  WHERE totrevenue IS NOT NULL
    AND totfuncexpns IS NOT NULL
  
  UNION ALL
  -- ---- 2016 -------------------------------------------------------
  SELECT
    2016,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)],
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  WHERE totrevenue IS NOT NULL
    AND totfuncexpns IS NOT NULL
  
  UNION ALL
  -- ---- 2017 -------------------------------------------------------
  SELECT
    2017,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)],
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2017`
  WHERE totrevenue IS NOT NULL
    AND totfuncexpns IS NOT NULL
)

SELECT
  filing_year,
  ABS(median_revenue - median_expenses) AS diff_median_rev_exp
FROM year_medians
ORDER BY diff_median_rev_exp
LIMIT 3;