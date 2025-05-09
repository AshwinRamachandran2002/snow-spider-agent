/* 3 smallest gaps (2012-2017) between the yearly median
   revenue and median functional expenses for Form-990 filers */
WITH all_990 AS (
    /* ---------- 2012 file (TAX_PD stored as TEXT) ---------- */
    SELECT
        TO_NUMBER(SUBSTR("tax_pd",1,4))  AS "year",
        "totrevenue"                     AS "revenue",
        "totfuncexpns"                   AS "expenses"
    FROM IRS_990.IRS_990."IRS_990_2012"

    UNION ALL
    /* ---------- 2013 file ---------- */
    SELECT
        FLOOR("tax_pd" / 100)            AS "year",
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2013"

    UNION ALL
    /* ---------- 2014 file ---------- */
    SELECT
        FLOOR("tax_pd" / 100),
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2014"

    UNION ALL
    /* ---------- 2015 file ---------- */
    SELECT
        FLOOR("tax_pd" / 100),
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2015"

    UNION ALL
    /* ---------- 2016 file ---------- */
    SELECT
        FLOOR("tax_pd" / 100),
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2016"

    UNION ALL
    /* ---------- 2017 file ---------- */
    SELECT
        FLOOR("tax_pd" / 100),
        "totrevenue",
        "totfuncexpns"
    FROM IRS_990.IRS_990."IRS_990_2017"
)

SELECT
    "year",
    ABS( MEDIAN("revenue") - MEDIAN("expenses") )  AS "median_difference"
FROM all_990
WHERE "year" BETWEEN 2012 AND 2017
GROUP BY "year"
ORDER BY "median_difference" ASC
LIMIT 3;