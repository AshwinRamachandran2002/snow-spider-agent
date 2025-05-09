SELECT
  "Year",
  ROUND(ABS(MEDIAN("totrevenue") - MEDIAN("totfuncexpns")), 4) AS "Difference"
FROM (
  SELECT
    '2012' AS "Year",
    "totrevenue",
    "totfuncexpns"
  FROM IRS_990.IRS_990."IRS_990_2012"
  WHERE "totrevenue" > 0 AND "totfuncexpns" > 0

  UNION ALL

  SELECT
    '2013' AS "Year",
    "totrevenue",
    "totfuncexpns"
  FROM IRS_990.IRS_990."IRS_990_2013"
  WHERE "totrevenue" > 0 AND "totfuncexpns" > 0

  UNION ALL

  SELECT
    '2014' AS "Year",
    "totrevenue",
    "totfuncexpns"
  FROM IRS_990.IRS_990."IRS_990_2014"
  WHERE "totrevenue" > 0 AND "totfuncexpns" > 0

  UNION ALL

  SELECT
    '2015' AS "Year",
    "totrevenue",
    "totfuncexpns"
  FROM IRS_990.IRS_990."IRS_990_2015"
  WHERE "totrevenue" > 0 AND "totfuncexpns" > 0

  UNION ALL

  SELECT
    '2016' AS "Year",
    "totrevenue",
    "totfuncexpns"
  FROM IRS_990.IRS_990."IRS_990_2016"
  WHERE "totrevenue" > 0 AND "totfuncexpns" > 0

  UNION ALL

  SELECT
    '2017' AS "Year",
    "totrevenue",
    "totfuncexpns"
  FROM IRS_990.IRS_990."IRS_990_2017"
  WHERE "totrevenue" > 0 AND "totfuncexpns" > 0
) AS AllData
GROUP BY "Year"
ORDER BY "Difference" ASC
LIMIT 3;