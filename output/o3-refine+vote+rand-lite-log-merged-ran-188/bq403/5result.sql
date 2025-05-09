-- Three years (2012‑2017) with the smallest absolute gap
-- between the median Total Revenue and the median Total Functional Expenses
WITH medians AS (
  SELECT
    CAST(_TABLE_SUFFIX AS INT64)                  AS yr,
    APPROX_QUANTILES(`totrevenue`,     2)[OFFSET(1)] AS med_rev,
    APPROX_QUANTILES(`totfuncexpns`, 2)[OFFSET(1)] AS med_exp
  FROM `bigquery-public-data.irs_990.irs_990_*`
  WHERE _TABLE_SUFFIX IN ('2012','2013','2014','2015','2016','2017')
  GROUP BY yr
)
SELECT
  yr  AS year,
  ABS(med_rev - med_exp) AS difference
FROM medians
ORDER BY difference ASC
LIMIT 3;