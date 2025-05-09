WITH all_returns AS (
  SELECT '2012' AS yr, totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  UNION ALL
  SELECT '2013', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  UNION ALL
  SELECT '2014', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  UNION ALL
  SELECT '2015', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  UNION ALL
  SELECT '2016', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  UNION ALL
  SELECT '2017', totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`
),
clean AS (
  SELECT yr, totrevenue, totfuncexpns
  FROM all_returns
  WHERE totrevenue IS NOT NULL
    AND totfuncexpns IS NOT NULL
),
medians AS (
  SELECT
    yr AS year,
    APPROX_QUANTILES(totrevenue  , 2)[OFFSET(1)] AS med_revenue,
    APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)] AS med_expenses
  FROM clean
  GROUP BY yr
),
diffs AS (
  SELECT
    year,
    ABS(med_revenue - med_expenses) AS absolute_difference
  FROM medians
)
SELECT
  year,
  absolute_difference
FROM diffs
ORDER BY absolute_difference
LIMIT 3;