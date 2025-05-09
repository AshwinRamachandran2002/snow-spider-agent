/* Three filing-years (2012‒2017) with the smallest absolute gap
   between median revenue and median functional expenses
   for organizations filing IRS Form 990                      */

WITH combined AS (
  -- Pull filing-year, revenue and expenses from each “full” 990 table
  SELECT CAST(SUBSTR(tax_pd,1,4) AS INT64) AS year,
         totrevenue                       AS revenue,
         totfuncexpns                     AS expenses
  FROM `bigquery-public-data.irs_990.irs_990_2012`
  UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64),
         totrevenue,
         totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2013`
  UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64),
         totrevenue,
         totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2014`
  UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64),
         totrevenue,
         totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2015`
  UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64),
         totrevenue,
         totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2016`
  UNION ALL
  SELECT CAST(SUBSTR(CAST(tax_pd AS STRING),1,4) AS INT64),
         totrevenue,
         totfuncexpns
  FROM `bigquery-public-data.irs_990.irs_990_2017`
),
filtered AS (
  -- Keep only 2012-2017 filings with non-null values
  SELECT *
  FROM combined
  WHERE year BETWEEN 2012 AND 2017
    AND revenue  IS NOT NULL
    AND expenses IS NOT NULL
),
yearly_medians AS (
  -- Median revenue and expenses by filing-year
  SELECT
    year,
    APPROX_QUANTILES(revenue , 2)[OFFSET(1)] AS median_revenue,
    APPROX_QUANTILES(expenses,2)[OFFSET(1)] AS median_expenses
  FROM filtered
  GROUP BY year
)
-- Return the three years with the smallest absolute difference
SELECT
  year,
  ABS(median_revenue - median_expenses) AS abs_difference
FROM yearly_medians
ORDER BY abs_difference
LIMIT 3;