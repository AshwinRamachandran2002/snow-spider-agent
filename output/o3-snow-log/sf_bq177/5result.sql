/* -------------------------------------------------------------------------
   Year-by-year average inpatient and outpatient Medicare costs (2011-2015)
   for the single provider whose cumulative 2011-2015 inpatient cost
   ( Σ average_medicare_payments × total_discharges ) is the highest.
   ------------------------------------------------------------------------- */
WITH top_provider AS (   ------------------------------------------------------
    /* 1. Identify the provider with the largest 5-year inpatient cost. */
    SELECT "provider_id"
    FROM (
        /*  Five separate inpatient files, 2011-2015  */
        SELECT "provider_id",
               ("average_medicare_payments" * "total_discharges") AS "cost"
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
        UNION ALL
        SELECT "provider_id",
               ("average_medicare_payments" * "total_discharges")
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
        UNION ALL
        SELECT "provider_id",
               ("average_medicare_payments" * "total_discharges")
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
        UNION ALL
        SELECT "provider_id",
               ("average_medicare_payments" * "total_discharges")
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
        UNION ALL
        SELECT "provider_id",
               ("average_medicare_payments" * "total_discharges")
        FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
    )
    GROUP BY "provider_id"
    ORDER BY SUM("cost") DESC NULLS LAST
    LIMIT 1
),
inpatient AS (           ------------------------------------------------------
    /* 2. Yearly average inpatient cost for the top provider. */
    SELECT '2011' AS "year",
           AVG("average_medicare_payments" * "total_discharges") AS "avg_inpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2012',
           AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2013',
           AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2014',
           AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2015',
           AVG("average_medicare_payments" * "total_discharges")
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
),
outpatient AS (          ------------------------------------------------------
    /* 3. Yearly average outpatient cost for the top provider. */
    SELECT '2011' AS "year",
           AVG("average_total_payments" * "outpatient_services") AS "avg_outpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2011"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2012',
           AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2012"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2013',
           AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2013"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2014',
           AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2014"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
    UNION ALL
    SELECT '2015',
           AVG("average_total_payments" * "outpatient_services")
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2015"
    WHERE "provider_id" IN (SELECT "provider_id" FROM top_provider)
)
SELECT  i."year",
        i."avg_inpatient_cost",
        o."avg_outpatient_cost"
FROM    inpatient  i
LEFT JOIN outpatient o
       ON i."year" = o."year"
ORDER BY i."year";