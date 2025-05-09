/*  Three years (2012-2017) with the smallest gap between
    median total revenue and median functional expenses across
    all IRS-990 return types (regular, EZ, PF).                */
WITH unified AS (
  /* ------------ Form 990 (regular) ------------ */
  SELECT
    '2012' AS filing_year,
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2012`

  UNION ALL
  SELECT
    SUBSTR(CAST(tax_pd AS STRING),1,4) AS filing_year,
    totrevenue,
    totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_*`
  WHERE _TABLE_SUFFIX BETWEEN '2013' AND '2017'

  /* ------------ Form 990-EZ -------------------- */
  UNION ALL
  SELECT
    '2012' AS filing_year,
    totrevnue  AS totrevenue,
    totexpns   AS totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_ez_2012`

  UNION ALL
  SELECT
    SUBSTR(CAST(tax_pd AS STRING),1,4) AS filing_year,
    totrevnue  AS totrevenue,
    totexpns   AS totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_ez_*`
  WHERE _TABLE_SUFFIX BETWEEN '2013' AND '2017'

  /* ------------ Form 990-PF -------------------- */
  UNION ALL
  SELECT
    CAST(tax_yr AS STRING) AS filing_year,
    totrcptperbks  AS totrevenue,
    totexpnspbks   AS totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_pf_*`
  WHERE _TABLE_SUFFIX BETWEEN '2012' AND '2017'
),

year_medians AS (
  SELECT
    filing_year,
    APPROX_QUANTILES(totrevenue ,2)[OFFSET(1)] AS median_revenue,
    APPROX_QUANTILES(totfuncexpns,2)[OFFSET(1)] AS median_expenses
  FROM unified
  WHERE filing_year BETWEEN '2012' AND '2017'
  GROUP BY filing_year
)

SELECT
  filing_year AS year,
  ABS(median_revenue - median_expenses) AS median_gap
FROM year_medians
ORDER BY median_gap
LIMIT 3;