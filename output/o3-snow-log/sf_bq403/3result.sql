/*  Find the three years (2012-2017) with the smallest gap between 
    median total revenue and median functional expenses               */

WITH year_medians AS (

    /* 2012 filings */
    SELECT '2012' AS "year",
           APPROX_PERCENTILE("totrevenue", 0.5)  AS "median_revenue",
           APPROX_PERCENTILE("totfuncexpns", 0.5) AS "median_expenses"
    FROM "IRS_990"."IRS_990"."IRS_990_2012"

    UNION ALL

    /* 2013 filings */
    SELECT '2013',
           APPROX_PERCENTILE("totrevenue", 0.5),
           APPROX_PERCENTILE("totfuncexpns", 0.5)
    FROM "IRS_990"."IRS_990"."IRS_990_2013"

    UNION ALL

    /* 2014 filings */
    SELECT '2014',
           APPROX_PERCENTILE("totrevenue", 0.5),
           APPROX_PERCENTILE("totfuncexpns", 0.5)
    FROM "IRS_990"."IRS_990"."IRS_990_2014"

    UNION ALL

    /* 2015 filings */
    SELECT '2015',
           APPROX_PERCENTILE("totrevenue", 0.5),
           APPROX_PERCENTILE("totfuncexpns", 0.5)
    FROM "IRS_990"."IRS_990"."IRS_990_2015"

    UNION ALL

    /* 2016 filings */
    SELECT '2016',
           APPROX_PERCENTILE("totrevenue", 0.5),
           APPROX_PERCENTILE("totfuncexpns", 0.5)
    FROM "IRS_990"."IRS_990"."IRS_990_2016"

    UNION ALL

    /* 2017 filings */
    SELECT '2017',
           APPROX_PERCENTILE("totrevenue", 0.5),
           APPROX_PERCENTILE("totfuncexpns", 0.5)
    FROM "IRS_990"."IRS_990"."IRS_990_2017"
)

SELECT
    "year",
    ROUND(ABS("median_revenue" - "median_expenses"), 4) AS "median_difference"
FROM year_medians
ORDER BY "median_difference" ASC NULLS LAST
LIMIT 3;