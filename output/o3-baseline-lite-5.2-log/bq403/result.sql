-- Median revenue vs. median functional expenses (IRS 990 filers, 2012‑2017)
SELECT
  CAST(year AS INT64)                           AS year,
  median_revenue,
  median_expenses,
  ABS(median_revenue - median_expenses) AS diff
FROM (
  SELECT
    _TABLE_SUFFIX                                AS year,
    APPROX_QUANTILES(totrevenue   , 2)[OFFSET(1)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns , 2)[OFFSET(1)] AS median_expenses
  FROM `bigquery-public-data.irs_990.irs_990_*`
  WHERE _TABLE_SUFFIX IN ('2012','2013','2014','2015','2016','2017')
  GROUP BY year
)
ORDER BY diff
LIMIT 3;