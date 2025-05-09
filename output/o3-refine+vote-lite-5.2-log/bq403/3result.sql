-- 3 years (2012‑2017) whose medians of total revenue and total functional
-- expenses are closest to one another among IRS 990 filers
WITH per_year AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64) AS year,
    APPROX_QUANTILES(totrevenue,    2)[OFFSET(1)] AS med_revenue,
    APPROX_QUANTILES(totfuncexpns,  2)[OFFSET(1)] AS med_expenses
  FROM `bigquery-public-data.irs_990.irs_990_*`
  WHERE _TABLE_SUFFIX BETWEEN '2012' AND '2017'     -- limit to 2012‑2017 tables
  GROUP BY year
)
SELECT
  year,
  ABS(med_revenue - med_expenses) AS abs_median_difference
FROM per_year
ORDER BY abs_median_difference
LIMIT 3;