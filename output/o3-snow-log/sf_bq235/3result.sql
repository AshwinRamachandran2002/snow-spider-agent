WITH
/* provider-level average total payment for all 2014 inpatient claims */
INPATIENT AS (
    SELECT
        "provider_id",
        MAX("provider_name")        AS "provider_name",   -- same for all rows of a provider
        AVG("average_total_payments") AS "avg_inpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),

/* provider-level average total payment for all 2014 outpatient claims */
OUTPATIENT AS (
    SELECT
        "provider_id",
        MAX("provider_name")         AS "provider_name",
        AVG("average_total_payments") AS "avg_outpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    GROUP BY "provider_id"
)

/* combine inpatient and outpatient averages and pick the provider
   with the highest combined average cost */
SELECT
    COALESCE(i."provider_id", o."provider_id")          AS "provider_id",
    COALESCE(i."provider_name", o."provider_name")      AS "provider_name",
    COALESCE(i."avg_inpatient_cost", 0) +
    COALESCE(o."avg_outpatient_cost", 0)                AS "combined_avg_cost",
    i."avg_inpatient_cost",
    o."avg_outpatient_cost"
FROM      INPATIENT  i
FULL JOIN OUTPATIENT o
       ON i."provider_id" = o."provider_id"
ORDER BY  "combined_avg_cost" DESC NULLS LAST
LIMIT 1;