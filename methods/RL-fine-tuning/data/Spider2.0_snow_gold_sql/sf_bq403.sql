WITH data AS (
  SELECT 2012 AS "Year", "totrevenue", "totfuncexpns"
  FROM IRS_990.IRS_990.IRS_990_2012
  UNION ALL
  SELECT 2013 AS "Year", "totrevenue", "totfuncexpns"
  FROM IRS_990.IRS_990.IRS_990_2013
  UNION ALL
  SELECT 2014 AS "Year", "totrevenue", "totfuncexpns"
  FROM IRS_990.IRS_990.IRS_990_2014
  UNION ALL
  SELECT 2015 AS "Year", "totrevenue", "totfuncexpns"
  FROM IRS_990.IRS_990.IRS_990_2015
  UNION ALL
  SELECT 2016 AS "Year", "totrevenue", "totfuncexpns"
  FROM IRS_990.IRS_990.IRS_990_2016
  UNION ALL
  SELECT 2017 AS "Year", "totrevenue", "totfuncexpns"
  FROM IRS_990.IRS_990.IRS_990_2017
)
SELECT
  "Year",
  ABS(ROUND(APPROX_PERCENTILE("totrevenue", 0.5) - APPROX_PERCENTILE("totfuncexpns", 0.5), 4)) AS "Difference"
FROM data
WHERE "totrevenue" > 0 AND "totfuncexpns" > 0
GROUP BY "Year"
ORDER BY "Difference" ASC
LIMIT 3;