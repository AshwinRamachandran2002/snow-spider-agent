WITH all_returns AS (
  -- bring together the six Form‑990 tables (one per year)
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
),
yearly_medians AS (
  SELECT
    filing_year,
    -- exact medians (nulls automatically ignored)
    PERCENTILE_CONT(totrevenue,   0.50) OVER (PARTITION BY filing_year) AS median_revenue,
    PERCENTILE_CONT(totfuncexpns, 0.50) OVER (PARTITION BY filing_year) AS median_expenses
  FROM all_returns
)
SELECT DISTINCT
  filing_year AS year,
  ABS(median_revenue - median_expenses) AS absolute_difference
FROM yearly_medians
ORDER BY absolute_difference
LIMIT 3;