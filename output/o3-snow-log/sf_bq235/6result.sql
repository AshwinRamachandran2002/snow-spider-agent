WITH
/* average outpatient cost per provider (2014) */
outpatient AS (
    SELECT
        "provider_id",
        MAX("provider_name")              AS "provider_name",
        AVG("average_total_payments")     AS "avg_outpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
    GROUP BY "provider_id"
),
/* average inpatient cost per provider (2014) */
inpatient AS (
    SELECT
        "provider_id",
        MAX("provider_name")              AS "provider_name",
        AVG("average_total_payments")     AS "avg_inpatient_cost"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    GROUP BY "provider_id"
)
/* combine and find highest combined average cost */
SELECT
    COALESCE(outpatient."provider_id", inpatient."provider_id")                   AS "provider_id",
    COALESCE(outpatient."provider_name", inpatient."provider_name")               AS "provider_name",
    COALESCE(outpatient."avg_outpatient_cost", 0)                                 AS "avg_outpatient_cost",
    COALESCE(inpatient."avg_inpatient_cost", 0)                                   AS "avg_inpatient_cost",
    COALESCE(outpatient."avg_outpatient_cost", 0) + COALESCE(inpatient."avg_inpatient_cost", 0)
                                                                                    AS "combined_avg_cost"
FROM outpatient
FULL OUTER JOIN inpatient
  ON outpatient."provider_id" = inpatient."provider_id"
ORDER BY "combined_avg_cost" DESC NULLS LAST
LIMIT 1;