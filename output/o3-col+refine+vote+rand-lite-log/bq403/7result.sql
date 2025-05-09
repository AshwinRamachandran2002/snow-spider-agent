/* Three years (2012-2017) with the smallest absolute gap between
   median revenue and median functional expenses for IRS-990 filers */
WITH union_990 AS (
  -- 2012 (tax_pd is STRING already)
  SELECT
    SUBSTR(tax_pd, 1, 4)           AS filing_year,
    totrevenue                     AS revenue,
    totfuncexpns                   AS expenses
  FROM `bigquery-public-data.irs_990.irs_990_2012`

  UNION ALL
  -- 2013-2017 (cast tax_pd INT64 → STRING)
  SELECT SUBSTR(CAST(tax_pd AS STRING), 1, 4), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013`

  UNION ALL
  SELECT SUBSTR(CAST(tax_pd AS STRING), 1, 4), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014`

  UNION ALL
  SELECT SUBSTR(CAST(tax_pd AS STRING), 1, 4), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015`

  UNION ALL
  SELECT SUBSTR(CAST(tax_pd AS STRING), 1, 4), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016`

  UNION ALL
  SELECT SUBSTR(CAST(tax_pd AS STRING), 1, 4), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`
)

SELECT
  filing_year,
  APPROX_QUANTILES(revenue , 2)[OFFSET(1)] AS median_revenue,
  APPROX_QUANTILES(expenses, 2)[OFFSET(1)] AS median_expenses,
  ABS(
    APPROX_QUANTILES(revenue , 2)[OFFSET(1)]
    -
    APPROX_QUANTILES(expenses, 2)[OFFSET(1)]
  )                                         AS abs_difference
FROM union_990
GROUP BY filing_year
ORDER BY abs_difference
LIMIT 3;