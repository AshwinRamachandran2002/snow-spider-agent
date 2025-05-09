WITH inpatient_data AS (
    SELECT 
        "provider_id", 
        "provider_name",
        SUM("average_total_payments" * "total_discharges") AS total_inpatient_payments,
        SUM("total_discharges") AS total_inpatient_discharges
    FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014"
    GROUP BY "provider_id", "provider_name"
),
outpatient_data AS (
    SELECT 
        "provider_id", 
        "provider_name",
        SUM("average_total_payments" * "outpatient_services") AS total_outpatient_payments,
        SUM("outpatient_services") AS total_outpatient_services
    FROM "CMS_DATA"."CMS_MEDICARE"."OUTPATIENT_CHARGES_2014"
    GROUP BY "provider_id", "provider_name"
),
combined_data AS (
    SELECT 
        COALESCE(ip."provider_id", op."provider_id") AS "provider_id",
        COALESCE(ip."provider_name", op."provider_name") AS "provider_name",
        COALESCE(ip.total_inpatient_payments, 0) AS total_inpatient_payments,
        COALESCE(ip.total_inpatient_discharges, 0) AS total_inpatient_discharges,
        COALESCE(op.total_outpatient_payments, 0) AS total_outpatient_payments,
        COALESCE(op.total_outpatient_services, 0) AS total_outpatient_services,
        (COALESCE(ip.total_inpatient_payments, 0) + COALESCE(op.total_outpatient_payments, 0)) AS total_combined_payments,
        (COALESCE(ip.total_inpatient_discharges, 0) + COALESCE(op.total_outpatient_services, 0)) AS total_combined_services,
        ROUND((COALESCE(ip.total_inpatient_payments, 0) + COALESCE(op.total_outpatient_payments, 0)) / NULLIF(
            (COALESCE(ip.total_inpatient_discharges, 0) + COALESCE(op.total_outpatient_services, 0)), 0), 4) AS combined_average_cost
    FROM inpatient_data ip
    FULL OUTER JOIN outpatient_data op
        ON ip."provider_id" = op."provider_id"
)
SELECT "provider_id", "provider_name", combined_average_cost
FROM combined_data
ORDER BY combined_average_cost DESC NULLS LAST
LIMIT 1;