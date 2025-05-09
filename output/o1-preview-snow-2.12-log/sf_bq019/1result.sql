WITH TopDRG AS (
    SELECT "drg_definition"
    FROM (
        SELECT "drg_definition", SUM("total_discharges") AS "total_discharges_per_drg"
        FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014"
        GROUP BY "drg_definition"
        ORDER BY "total_discharges_per_drg" DESC NULLS LAST
        LIMIT 1
    )
),
TopCities AS (
    SELECT "provider_city", SUM("total_discharges") AS "total_city_discharges"
    FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014" AS t
    JOIN TopDRG ON t."drg_definition" = TopDRG."drg_definition"
    GROUP BY "provider_city"
    ORDER BY "total_city_discharges" DESC NULLS LAST
    LIMIT 3
)
SELECT t."provider_city" AS "City",
       ROUND(
           SUM(t."total_discharges" * t."average_total_payments") / SUM(t."total_discharges"), 4
       ) AS "Weighted_Average_Total_Payments"
FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014" AS t
JOIN TopDRG ON t."drg_definition" = TopDRG."drg_definition"
JOIN TopCities ON t."provider_city" = TopCities."provider_city"
GROUP BY t."provider_city";