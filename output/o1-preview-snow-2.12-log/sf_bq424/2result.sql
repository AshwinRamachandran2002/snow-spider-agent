SELECT c."short_name" AS "Country_Name", t."value" AS "Total_Long_Term_Debt"
FROM "WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA" t
JOIN "WORLD_BANK"."WORLD_BANK_WDI"."COUNTRY_SUMMARY" c
    ON t."country_code" = c."country_code"
JOIN (
    SELECT "country_code", MAX("year") AS "latest_year"
    FROM "WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA"
    WHERE "indicator_code" = 'DT.DOD.DLXF.CD' AND "value" IS NOT NULL
    GROUP BY "country_code"
) latest
    ON t."country_code" = latest."country_code" AND t."year" = latest."latest_year"
WHERE t."indicator_code" = 'DT.DOD.DLXF.CD'
  AND c."region" IS NOT NULL AND TRIM(c."region") != ''
ORDER BY t."value" DESC NULLS LAST
LIMIT 10;