-- Three years (2012-2017) whose median revenue and expense values
-- are closest (smallest absolute difference)
WITH filings AS (
  -- 2012
  SELECT
    CAST(SUBSTR(CAST(tax_pd AS STRING), 1, 4) AS INT64) AS year,
    totrevenue   AS revenue,
    totfuncexpns AS expenses
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  UNION ALL
  -- 2013
  SELECT
    CAST(SUBSTR(CAST(tax_pd AS STRING), 1, 4) AS INT64),
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  UNION ALL
  -- 2014
  SELECT
    CAST(SUBSTR(CAST(tax_pd AS STRING), 1, 4) AS INT64),
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  UNION ALL
  -- 2015
  SELECT
    CAST(SUBSTR(CAST(tax_pd AS STRING), 1, 4) AS INT64),
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  UNION ALL
  -- 2016
  SELECT
    CAST(SUBSTR(CAST(tax_pd AS STRING), 1, 4) AS INT64),
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  UNION ALL
  -- 2017
  SELECT
    CAST(SUBSTR(CAST(tax_pd AS STRING), 1, 4) AS INT64),
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`
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
  ABS(median_revenue - median_expenses) AS median_rev_exp_diff
FROM medians
ORDER BY median_rev_exp_diff
LIMIT 3;