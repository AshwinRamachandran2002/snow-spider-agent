WITH inpatient_totals AS (
    SELECT
        "provider_id",
        SUM("average_total_payments" * "total_discharges") AS total_inpatient_payments,
        SUM("total_discharges") AS total_inpatient_services
    FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014"
    GROUP BY "provider_id"
),
outpatient_totals AS (
    SELECT
        "provider_id",
        SUM("average_total_payments" * "outpatient_services") AS total_outpatient_payments,
        SUM("outpatient_services") AS total_outpatient_services
    FROM "CMS_DATA"."CMS_MEDICARE"."OUTPATIENT_CHARGES_2014"
    GROUP BY "provider_id"
),
combined_totals AS (
    SELECT
        COALESCE(i."provider_id", o."provider_id") AS "provider_id",
        (COALESCE(i.total_inpatient_payments, 0) + COALESCE(o.total_outpatient_payments, 0)) / (COALESCE(i.total_inpatient_services, 0) + COALESCE(o.total_outpatient_services, 0)) AS combined_average_cost
    FROM inpatient_totals i
    FULL OUTER JOIN outpatient_totals o ON i."provider_id" = o."provider_id"
    WHERE (COALESCE(i.total_inpatient_services, 0) + COALESCE(o.total_outpatient_services, 0)) > 0
),
provider_names AS (
    SELECT DISTINCT "provider_id", "provider_name"
    FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014"
    UNION
    SELECT DISTINCT "provider_id", "provider_name"
    FROM "CMS_DATA"."CMS_MEDICARE"."OUTPATIENT_CHARGES_2014"
)
SELECT
    ct."provider_id",
    pn."provider_name",
    ROUND(ct.combined_average_cost, 4) AS "combined_average_cost"
FROM combined_totals ct
JOIN provider_names pn ON ct."provider_id" = pn."provider_id"
ORDER BY ct.combined_average_cost DESC NULLS LAST
LIMIT 1;