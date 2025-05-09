-- Three years (2012-2017) whose median revenue and median functional expenses 
-- are closest together for Form-990 filers
WITH year_medians AS (
    /*----- 2012 -----*/
    SELECT 2012 AS "year",
           MEDIAN("totrevenue")   AS "med_rev",
           MEDIAN("totfuncexpns") AS "med_exp"
    FROM "IRS_990"."IRS_990"."IRS_990_2012"
    WHERE "totrevenue"   IS NOT NULL
      AND "totfuncexpns" IS NOT NULL

    UNION ALL
    /*----- 2013 -----*/
    SELECT 2013,
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM "IRS_990"."IRS_990"."IRS_990_2013"
    WHERE "totrevenue"   IS NOT NULL
      AND "totfuncexpns" IS NOT NULL

    UNION ALL
    /*----- 2014 -----*/
    SELECT 2014,
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM "IRS_990"."IRS_990"."IRS_990_2014"
    WHERE "totrevenue"   IS NOT NULL
      AND "totfuncexpns" IS NOT NULL

    UNION ALL
    /*----- 2015 -----*/
    SELECT 2015,
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM "IRS_990"."IRS_990"."IRS_990_2015"
    WHERE "totrevenue"   IS NOT NULL
      AND "totfuncexpns" IS NOT NULL

    UNION ALL
    /*----- 2016 -----*/
    SELECT 2016,
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM "IRS_990"."IRS_990"."IRS_990_2016"
    WHERE "totrevenue"   IS NOT NULL
      AND "totfuncexpns" IS NOT NULL

    UNION ALL
    /*----- 2017 -----*/
    SELECT 2017,
           MEDIAN("totrevenue"),
           MEDIAN("totfuncexpns")
    FROM "IRS_990"."IRS_990"."IRS_990_2017"
    WHERE "totrevenue"   IS NOT NULL
      AND "totfuncexpns" IS NOT NULL
)

SELECT
    "year",
    ABS("med_rev" - "med_exp") AS "median_abs_difference"
FROM year_medians
ORDER BY "median_abs_difference" ASC
LIMIT 3;