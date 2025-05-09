WITH medians AS (
  SELECT 2012 AS year,
         APPROX_QUANTILES(totrevenue, 2)[OFFSET(1)]   AS med_rev,
         APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)] AS med_exp
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  UNION ALL
  SELECT 2013,
         APPROX_QUANTILES(totrevenue, 2)[OFFSET(1)],
         APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  UNION ALL
  SELECT 2014,
         APPROX_QUANTILES(totrevenue, 2)[OFFSET(1)],
         APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  UNION ALL
  SELECT 2015,
         APPROX_QUANTILES(totrevenue, 2)[OFFSET(1)],
         APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  UNION ALL
  SELECT 2016,
         APPROX_QUANTILES(totrevenue, 2)[OFFSET(1)],
         APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  UNION ALL
  SELECT 2017,
         APPROX_QUANTILES(totrevenue, 2)[OFFSET(1)],
         APPROX_QUANTILES(totfuncexpns, 2)[OFFSET(1)]
  FROM `bigquery-public-data.irs_990.irs_990_2017`
)
SELECT
  year,
  ABS(med_rev - med_exp) AS abs_difference_between_medians
FROM medians
ORDER BY abs_difference_between_medians
LIMIT 3;