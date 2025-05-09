/*  Smallest absolute gap between median revenue and median functional expenses
    for IRS-990 filers, years 2012-2017                                          */
WITH yearly_medians AS (
    SELECT '2012' AS "year",
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totrevenue")   AS "median_revenue",
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totfuncexpns") AS "median_expenses"
    FROM IRS_990.IRS_990."IRS_990_2012"

    UNION ALL
    SELECT '2013',
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totrevenue"),
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2013"

    UNION ALL
    SELECT '2014',
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totrevenue"),
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2014"

    UNION ALL
    SELECT '2015',
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totrevenue"),
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2015"

    UNION ALL
    SELECT '2016',
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totrevenue"),
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2016"

    UNION ALL
    SELECT '2017',
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totrevenue"),
           PERCENTILE_CONT(0.5) WITHIN GROUP (ORDER BY "totfuncexpns")
    FROM IRS_990.IRS_990."IRS_990_2017"
)

SELECT
    "year",
    ROUND(ABS("median_revenue" - "median_expenses"), 2) AS "median_rev_vs_exp_gap"
FROM yearly_medians
ORDER BY "median_rev_vs_exp_gap" ASC
LIMIT 3;