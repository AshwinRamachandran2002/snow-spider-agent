-- Three years (2012-2017) with the smallest gap between
-- median total revenue and median total functional expenses
WITH filings AS (
  SELECT 2012 AS filing_year, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  UNION ALL
  SELECT 2013, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  UNION ALL
  SELECT 2014, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  UNION ALL
  SELECT 2015, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  UNION ALL
  SELECT 2016, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  UNION ALL
  SELECT 2017, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`
)
SELECT
  filing_year AS year,
  APPROX_QUANTILES(totrevenue,   2)[OFFSET(1)] AS median_revenue,
  APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)] AS median_expenses,
  ABS(
    APPROX_QUANTILES(totrevenue,   2)[OFFSET(1)] -
    APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)]
  ) AS abs_difference
FROM filings
GROUP BY filing_year
ORDER BY abs_difference
LIMIT 3;