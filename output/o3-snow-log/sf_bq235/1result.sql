WITH
    inpatient AS (
        SELECT
            "provider_id",
            MIN("provider_name")                              AS "provider_name_inp",
            AVG("average_total_payments")                     AS "avg_inpatient_cost"
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
        GROUP BY "provider_id"
    ),
    outpatient AS (
        SELECT
            "provider_id",
            MIN("provider_name")                              AS "provider_name_out",
            AVG("average_total_payments")                     AS "avg_outpatient_cost"
        FROM CMS_DATA.CMS_MEDICARE.OUTPATIENT_CHARGES_2014
        GROUP BY "provider_id"
    )

SELECT
    COALESCE(i."provider_id", o."provider_id")                            AS "provider_id",
    COALESCE(i."provider_name_inp", o."provider_name_out")                AS "provider_name",
    COALESCE(i."avg_inpatient_cost", 0)                                   AS "avg_inpatient_cost_2014",
    COALESCE(o."avg_outpatient_cost", 0)                                  AS "avg_outpatient_cost_2014",
    COALESCE(i."avg_inpatient_cost", 0) + COALESCE(o."avg_outpatient_cost", 0) 
                                                                           AS "combined_avg_cost_2014"
FROM inpatient  i
FULL OUTER JOIN outpatient o
       ON i."provider_id" = o."provider_id"
ORDER BY "combined_avg_cost_2014" DESC NULLS LAST
LIMIT 1;