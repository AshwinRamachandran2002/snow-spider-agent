WITH Most_Common_Diagnosis AS (
    SELECT "drg_definition"
    FROM (
        SELECT "drg_definition", SUM("total_discharges") AS "total_discharge"
        FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014"
        GROUP BY "drg_definition"
        ORDER BY "total_discharge" DESC NULLS LAST
        LIMIT 1
    )
),
Top_Cities AS (
    SELECT "provider_city"
    FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014"
    WHERE "drg_definition" = (SELECT "drg_definition" FROM Most_Common_Diagnosis)
    GROUP BY "provider_city"
    ORDER BY SUM("total_discharges") DESC NULLS LAST
    LIMIT 3
)
SELECT "provider_city" AS "City",
       ROUND(AVG("average_total_payments"), 4) AS "Average_Payment"
FROM "CMS_DATA"."CMS_MEDICARE"."INPATIENT_CHARGES_2014"
WHERE "drg_definition" = (SELECT "drg_definition" FROM Most_Common_Diagnosis)
  AND "provider_city" IN (SELECT "provider_city" FROM Top_Cities)
GROUP BY "provider_city"
ORDER BY "Average_Payment" DESC NULLS LAST;