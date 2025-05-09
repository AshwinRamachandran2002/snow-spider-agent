WITH per_year_stats AS (
  SELECT
    2012 AS Year,
    APPROX_QUANTILES(totrevenue, 1001)[OFFSET(500)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns, 1001)[OFFSET(500)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  WHERE totrevenue > 0 AND totfuncexpns > 0
  UNION ALL
  SELECT
    2013 AS Year,
    APPROX_QUANTILES(totrevenue, 1001)[OFFSET(500)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns, 1001)[OFFSET(500)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  WHERE totrevenue > 0 AND totfuncexpns > 0
  UNION ALL
  SELECT
    2014 AS Year,
    APPROX_QUANTILES(totrevenue, 1001)[OFFSET(500)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns, 1001)[OFFSET(500)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  WHERE totrevenue > 0 AND totfuncexpns > 0
  UNION ALL
  SELECT
    2015 AS Year,
    APPROX_QUANTILES(totrevenue, 1001)[OFFSET(500)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns, 1001)[OFFSET(500)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  WHERE totrevenue > 0 AND totfuncexpns > 0
  UNION ALL
  SELECT
    2016 AS Year,
    APPROX_QUANTILES(totrevenue, 1001)[OFFSET(500)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns, 1001)[OFFSET(500)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  WHERE totrevenue > 0 AND totfuncexpns > 0
  UNION ALL
  SELECT
    2017 AS Year,
    APPROX_QUANTILES(totrevenue, 1001)[OFFSET(500)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns, 1001)[OFFSET(500)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_2017`
  WHERE totrevenue > 0 AND totfuncexpns > 0
)
SELECT
  Year,
  ROUND(ABS(median_revenue - median_expenses), 4) AS Difference
FROM per_year_stats
ORDER BY Difference ASC
LIMIT 3;