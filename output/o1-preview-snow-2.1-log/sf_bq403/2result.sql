SELECT "Year", "Difference"
FROM (
    SELECT '2012' AS "Year", ROUND(ABS(MEDIAN("totrevenue") - MEDIAN("totfuncexpns")), 4) AS "Difference"
    FROM IRS_990."IRS_990"."IRS_990_2012"
    WHERE "totrevenue" IS NOT NULL AND "totfuncexpns" IS NOT NULL
    UNION ALL
    SELECT '2013' AS "Year", ROUND(ABS(MEDIAN("totrevenue") - MEDIAN("totfuncexpns")), 4) AS "Difference"
    FROM IRS_990."IRS_990"."IRS_990_2013"
    WHERE "totrevenue" IS NOT NULL AND "totfuncexpns" IS NOT NULL
    UNION ALL
    SELECT '2014' AS "Year", ROUND(ABS(MEDIAN("totrevenue") - MEDIAN("totfuncexpns")), 4) AS "Difference"
    FROM IRS_990."IRS_990"."IRS_990_2014"
    WHERE "totrevenue" IS NOT NULL AND "totfuncexpns" IS NOT NULL
    UNION ALL
    SELECT '2015' AS "Year", ROUND(ABS(MEDIAN("totrevenue") - MEDIAN("totfuncexpns")), 4) AS "Difference"
    FROM IRS_990."IRS_990"."IRS_990_2015"
    WHERE "totrevenue" IS NOT NULL AND "totfuncexpns" IS NOT NULL
    UNION ALL
    SELECT '2016' AS "Year", ROUND(ABS(MEDIAN("totrevenue") - MEDIAN("totfuncexpns")), 4) AS "Difference"
    FROM IRS_990."IRS_990"."IRS_990_2016"
    WHERE "totrevenue" IS NOT NULL AND "totfuncexpns" IS NOT NULL
    UNION ALL
    SELECT '2017' AS "Year", ROUND(ABS(MEDIAN("totrevenue") - MEDIAN("totfuncexpns")), 4) AS "Difference"
    FROM IRS_990."IRS_990"."IRS_990_2017"
    WHERE "totrevenue" IS NOT NULL AND "totfuncexpns" IS NOT NULL
) AS yearly_differences
ORDER BY "Difference" ASC NULLS LAST
LIMIT 3;