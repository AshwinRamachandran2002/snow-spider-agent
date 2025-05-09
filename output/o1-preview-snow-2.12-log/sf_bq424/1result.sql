SELECT cs."short_name" AS "Country_Name", ROUND(SUM(id."value"), 4) AS "Total_Long_Term_Debt"
FROM "WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA" AS id
JOIN "WORLD_BANK"."WORLD_BANK_WDI"."COUNTRY_SUMMARY" AS cs
  ON id."country_code" = cs."country_code"
WHERE id."indicator_name" = 'External debt stocks, long-term (DOD, current US$)'
  AND cs."region" IS NOT NULL
  AND cs."region" != ''
  AND id."value" IS NOT NULL
GROUP BY cs."short_name"
ORDER BY "Total_Long_Term_Debt" DESC NULLS LAST
LIMIT 10;