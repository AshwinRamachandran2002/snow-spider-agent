SELECT "indicator_name", ROUND(MAX(CAST("value" AS FLOAT)), 4) AS "value"
FROM WORLD_BANK.WORLD_BANK_WDI.INDICATORS_DATA
WHERE "country_name" = 'Russian Federation'
  AND "indicator_name" ILIKE '%debt%'
  AND "value" IS NOT NULL
GROUP BY "indicator_name"
ORDER BY "value" DESC NULLS LAST
LIMIT 3;