WITH yearly AS (
    /* 2012 */
    SELECT '2012'     AS "year",
           MEDIAN("totrevenue")    AS "median_revenue",
           MEDIAN("totfuncexpns")  AS "median_expenses"
    FROM IRS_990.IRS_990."IRS_990_2012"

    UNION ALL
    /* 2013 */
    SELECT '2013',
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2013"

    UNION ALL
    /* 2014 */
    SELECT '2014',
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2014"

    UNION ALL
    /* 2015 */
    SELECT '2015',
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2015"

    UNION ALL
    /* 2016 */
    SELECT '2016',
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2016"

    UNION ALL
    /* 2017 */
    SELECT '2017',
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2017"
)

SELECT
    "year",
    ABS("median_revenue" - "median_expenses") AS "median_diff"
FROM yearly
ORDER BY "median_diff" ASC NULLS LAST
LIMIT 3;