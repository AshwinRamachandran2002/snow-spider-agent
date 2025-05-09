SELECT id."country_name", ROUND(SUM(id."value"), 4) AS "Total_Long_Term_Debt"
FROM "WORLD_BANK"."WORLD_BANK_WDI"."INDICATORS_DATA" AS id
JOIN "WORLD_BANK"."WORLD_BANK_WDI"."COUNTRY_SUMMARY" AS cs
  ON id."country_code" = cs."country_code"
WHERE id."indicator_code" = 'DT.DOD.DLXF.CD'
  AND id."value" IS NOT NULL
  AND cs."region" IS NOT NULL AND cs."region" <> ''
  AND LENGTH(cs."country_code") = 3
GROUP BY id."country_name"
ORDER BY "Total_Long_Term_Debt" DESC NULLS LAST
LIMIT 10;