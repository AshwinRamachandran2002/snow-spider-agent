WITH most_common_drg AS (
    SELECT "drg_definition"
    FROM (
        SELECT "drg_definition", SUM("total_discharges") AS "total_cases"
        FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
        GROUP BY "drg_definition"
        ORDER BY "total_cases" DESC NULLS LAST
        LIMIT 1
    )
),
top_three_cities AS (
    SELECT "provider_city"
    FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
    WHERE "drg_definition" = (SELECT "drg_definition" FROM most_common_drg)
    GROUP BY "provider_city"
    ORDER BY SUM("total_discharges") DESC NULLS LAST
    LIMIT 3
)
SELECT "provider_city" AS "City",
       ROUND(AVG("average_total_payments"), 4) AS "Average_Payment"
FROM CMS_DATA.CMS_MEDICARE.INPATIENT_CHARGES_2014
WHERE "drg_definition" = (SELECT "drg_definition" FROM most_common_drg)
  AND "provider_city" IN (SELECT "provider_city" FROM top_three_cities)
GROUP BY "provider_city"
ORDER BY SUM("total_discharges") DESC NULLS LAST;