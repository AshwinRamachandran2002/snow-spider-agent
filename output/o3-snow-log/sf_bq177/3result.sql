/*  Year-by-year average INPATIENT vs. OUTPATIENT Medicare cost
    for the provider that incurred the single highest cumulative
    INPATIENT Medicare cost during CY-2011 through CY-2015          */

WITH inpatient_union AS (      /* every inpatient row with year-tagged cost */
    SELECT 2011 AS "yr",
           "provider_id",
           "total_discharges" * "average_medicare_payments" AS "row_cost"
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2011"
    UNION ALL
    SELECT 2012, "provider_id",
           "total_discharges" * "average_medicare_payments"
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2012"
    UNION ALL
    SELECT 2013, "provider_id",
           "total_discharges" * "average_medicare_payments"
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2013"
    UNION ALL
    SELECT 2014, "provider_id",
           "total_discharges" * "average_medicare_payments"
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2014"
    UNION ALL
    SELECT 2015, "provider_id",
           "total_discharges" * "average_medicare_payments"
    FROM CMS_DATA.CMS_MEDICARE."INPATIENT_CHARGES_2015"
),

/* Identify the single provider with the greatest cumulative inpatient spend */
top_provider AS (
    SELECT  "provider_id"
    FROM    inpatient_union
    GROUP BY "provider_id"
    ORDER BY SUM("row_cost") DESC NULLS LAST
    LIMIT   1
),

/* Yearly average inpatient cost for that provider */
inpatient_yearly AS (
    SELECT  "yr",
            AVG("row_cost") AS "avg_inpatient_cost"
    FROM    inpatient_union
    WHERE   "provider_id" IN (SELECT "provider_id" FROM top_provider)
    GROUP BY "yr"
),

/* Build a union of all outpatient rows with year-tagged cost */
outpatient_union AS (
    SELECT 2011 AS "yr",
           "provider_id",
           "outpatient_services" * "average_total_payments" AS "row_cost"
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2011"
    UNION ALL
    SELECT 2012, "provider_id",
           "outpatient_services" * "average_total_payments"
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2012"
    UNION ALL
    SELECT 2013, "provider_id",
           "outpatient_services" * "average_total_payments"
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2013"
    UNION ALL
    SELECT 2014, "provider_id",
           "outpatient_services" * "average_total_payments"
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2014"
    UNION ALL
    SELECT 2015, "provider_id",
           "outpatient_services" * "average_total_payments"
    FROM CMS_DATA.CMS_MEDICARE."OUTPATIENT_CHARGES_2015"
),

/* Yearly average outpatient cost for the same provider */
outpatient_yearly AS (
    SELECT  "yr",
            AVG("row_cost") AS "avg_outpatient_cost"
    FROM    outpatient_union
    WHERE   "provider_id" IN (SELECT "provider_id" FROM top_provider)
    GROUP BY "yr"
)

/* Final result: side-by-side yearly averages 2011-2015 */
SELECT      i."yr",
            i."avg_inpatient_cost",
            o."avg_outpatient_cost"
FROM        inpatient_yearly  i
LEFT JOIN   outpatient_yearly o
       ON   i."yr" = o."yr"
ORDER BY    i."yr";