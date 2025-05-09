WITH inpatient AS (
    SELECT 
        "provider_id",
        MIN("provider_name")                       AS "provider_name",
        AVG("average_total_payments")              AS "avg_inpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
outpatient AS (
    SELECT 
        "provider_id",
        MIN("provider_name")                       AS "provider_name",
        AVG("average_total_payments")              AS "avg_outpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
combined AS (
    SELECT
        COALESCE(i."provider_id", o."provider_id")               AS "provider_id",
        COALESCE(i."provider_name", o."provider_name")           AS "provider_name",
        COALESCE(i."avg_inpatient_cost", 0)                      AS "avg_inpatient_cost",
        COALESCE(o."avg_outpatient_cost", 0)                     AS "avg_outpatient_cost",
        COALESCE(i."avg_inpatient_cost", 0) + 
        COALESCE(o."avg_outpatient_cost", 0)                     AS "combined_avg_cost"
    FROM inpatient i
    FULL OUTER JOIN outpatient o
        ON i."provider_id" = o."provider_id"
)
SELECT 
    "provider_id",
    "provider_name",
    "avg_inpatient_cost",
    "avg_outpatient_cost",
    "combined_avg_cost"
FROM combined
ORDER BY "combined_avg_cost" DESC NULLS LAST
LIMIT 1;