-- three years (2012‑2017) whose median revenue and median functional expenses
-- are closest together for organizations filing the long‑form 990
WITH combined AS (
  SELECT 2012 AS year, totrevenue, totfuncexpns
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
yearly_stats AS (
  SELECT
    year,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)] AS median_expenses
  FROM combined
  WHERE totrevenue   IS NOT NULL
    AND totfuncexpns IS NOT NULL
  GROUP BY year
)
SELECT
  year,
  ABS(median_revenue - median_expenses) AS absolute_difference
FROM yearly_stats
ORDER BY absolute_difference
LIMIT 3;