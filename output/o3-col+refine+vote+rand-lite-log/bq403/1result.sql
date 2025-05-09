/* 3 calendar years (2012-2017) whose median revenue and
   median expenses are closest, across all 990 filing types */
WITH filings AS (

  /* ---------- “regular” Form-990 (2012-2017) ---------- */
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64) AS yr,
         totrevenue   AS rev,
         totfuncexpns AS exp
  FROM `bigquery-public-data.irs_990.irs_990_2012` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevenue, totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`

  /* ---------- Form-990 EZ (2012-2017) ----------------- */
  UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevnue AS rev, totexpns AS exp
  FROM `bigquery-public-data.irs_990.irs_990_ez_2012` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevnue, totexpns
  FROM `bigquery-public-data.irs_990.irs_990_ez_2013` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevnue, totexpns
  FROM `bigquery-public-data.irs_990.irs_990_ez_2014` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevnue, totexpns
  FROM `bigquery-public-data.irs_990.irs_990_ez_2015` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevnue, totexpns
  FROM `bigquery-public-data.irs_990.irs_990_ez_2016` UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64), totrevnue, totexpns
  FROM `bigquery-public-data.irs_990.irs_990_ez_2017`

  /* ---------- Form-990 PF (2012-2016) ----------------- */
  UNION ALL
  SELECT tax_yr AS yr,
         totrcptperbks AS rev,
         totexpnspbks AS exp
  FROM `bigquery-public-data.irs_990.irs_990_pf_2012` UNION ALL
  SELECT tax_yr, totrcptperbks, totexpnspbks
  FROM `bigquery-public-data.irs_990.irs_990_pf_2013` UNION ALL
  SELECT tax_yr, totrcptperbks, totexpnspbks
  FROM `bigquery-public-data.irs_990.irs_990_pf_2014` UNION ALL
  SELECT tax_yr, totrcptperbks, totexpnspbks
  FROM `bigquery-public-data.irs_990.irs_990_pf_2015` UNION ALL
  SELECT tax_yr, totrcptperbks, totexpnspbks
  FROM `bigquery-public-data.irs_990.irs_990_pf_2016`
)

SELECT
  yr,
  APPROX_QUANTILES(rev, 2)[OFFSET(1)] AS median_revenue,
  APPROX_QUANTILES(exp, 2)[OFFSET(1)] AS median_expenses,
  ABS(
    APPROX_QUANTILES(rev, 2)[OFFSET(1)] -
    APPROX_QUANTILES(exp, 2)[OFFSET(1)]
  ) AS abs_difference
FROM filings
WHERE yr BETWEEN 2012 AND 2017
GROUP BY yr
ORDER BY abs_difference
LIMIT 3;