WITH medians AS (
  SELECT
    2012 AS Year,
    stat.*
  FROM (
    SELECT
      APPROX_QUANTILES(totrevenue, 1000)[OFFSET(500)] AS median_revenue,
      APPROX_QUANTILES(totfuncexpns, 1000)[OFFSET(500)] AS median_expenses
    FROM `bigquery-public-data.irs_990.irs_990_2012`
    WHERE totrevenue > 0 AND totfuncexpns > 0
  ) AS stat
  UNION ALL
  SELECT
    2013 AS Year,
    stat.*
  FROM (
    SELECT
      APPROX_QUANTILES(totrevenue, 1000)[OFFSET(500)] AS median_revenue,
      APPROX_QUANTILES(totfuncexpns, 1000)[OFFSET(500)] AS median_expenses
    FROM `bigquery-public-data.irs_990.irs_990_2013`
    WHERE totrevenue > 0 AND totfuncexpns > 0
  ) AS stat
  UNION ALL
  SELECT
    2014 AS Year,
    stat.*
  FROM (
    SELECT
      APPROX_QUANTILES(totrevenue, 1000)[OFFSET(500)] AS median_revenue,
      APPROX_QUANTILES(totfuncexpns, 1000)[OFFSET(500)] AS median_expenses
    FROM `bigquery-public-data.irs_990.irs_990_2014`
    WHERE totrevenue > 0 AND totfuncexpns > 0
  ) AS stat
  UNION ALL
  SELECT
    2015 AS Year,
    stat.*
  FROM (
    SELECT
      APPROX_QUANTILES(totrevenue, 1000)[OFFSET(500)] AS median_revenue,
      APPROX_QUANTILES(totfuncexpns, 1000)[OFFSET(500)] AS median_expenses
    FROM `bigquery-public-data.irs_990.irs_990_2015`
    WHERE totrevenue > 0 AND totfuncexpns > 0
  ) AS stat
  UNION ALL
  SELECT
    2016 AS Year,
    stat.*
  FROM (
    SELECT
      APPROX_QUANTILES(totrevenue, 1000)[OFFSET(500)] AS median_revenue,
      APPROX_QUANTILES(totfuncexpns, 1000)[OFFSET(500)] AS median_expenses
    FROM `bigquery-public-data.irs_990.irs_990_2016`
    WHERE totrevenue > 0 AND totfuncexpns > 0
  ) AS stat
  UNION ALL
  SELECT
    2017 AS Year,
    stat.*
  FROM (
    SELECT
      APPROX_QUANTILES(totrevenue, 1000)[OFFSET(500)] AS median_revenue,
      APPROX_QUANTILES(totfuncexpns, 1000)[OFFSET(500)] AS median_expenses
    FROM `bigquery-public-data.irs_990.irs_990_2017`
    WHERE totrevenue > 0 AND totfuncexpns > 0
  ) AS stat
)
SELECT
  Year,
  ROUND(ABS(median_revenue - median_expenses), 4) AS Difference
FROM medians
ORDER BY Difference
LIMIT 3;