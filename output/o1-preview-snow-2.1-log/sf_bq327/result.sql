SELECT COUNT(DISTINCT "indicator_code") AS "Number_of_Debt_Indicators"
FROM "WORLD_BANK"."WORLD_BANK_INTL_DEBT"."INTERNATIONAL_DEBT"
WHERE "country_code" = 'RUS'
  AND "indicator_code" LIKE 'DT.%'
  AND "value" = 0