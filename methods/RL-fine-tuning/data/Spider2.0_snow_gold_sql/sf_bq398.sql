SELECT "indicator_name", SUM("value") AS "total_debt"
FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA
WHERE "country_code" = 'RUS' AND "indicator_name" ILIKE '%debt%' AND "value" IS NOT NULL
GROUP BY "indicator_name"
ORDER BY "total_debt" DESC NULLS LAST
LIMIT 3;