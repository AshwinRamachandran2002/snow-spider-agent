-- Years (2012-2017) with the three smallest absolute gaps between 
-- median total revenue and median functional expenses
WITH all990 AS (
    SELECT 2012 AS "yr", "totrevenue" AS "rev", "totfuncexpns" AS "exp"
    FROM IRS_990.IRS_990."IRS_990_2012"
    UNION ALL
    SELECT 2013, "totrevenue", "totfuncexpns" FROM IRS_990.IRS_990."IRS_990_2013"
    UNION ALL
    SELECT 2014, "totrevenue", "totfuncexpns" FROM IRS_990.IRS_990."IRS_990_2014"
    UNION ALL
    SELECT 2015, "totrevenue", "totfuncexpns" FROM IRS_990.IRS_990."IRS_990_2015"
    UNION ALL
    SELECT 2016, "totrevenue", "totfuncexpns" FROM IRS_990.IRS_990."IRS_990_2016"
    UNION ALL
    SELECT 2017, "totrevenue", "totfuncexpns" FROM IRS_990.IRS_990."IRS_990_2017"
)
SELECT
    "yr",
    ABS(
        APPROX_PERCENTILE("rev", 0.5) - 
        APPROX_PERCENTILE("exp", 0.5)
    ) AS "median_abs_diff"
FROM all990
GROUP BY "yr"
ORDER BY "median_abs_diff" ASC NULLS LAST
LIMIT 3;