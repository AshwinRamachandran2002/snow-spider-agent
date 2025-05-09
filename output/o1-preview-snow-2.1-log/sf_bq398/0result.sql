SELECT "indicator_name", ROUND(MAX("value"), 4) AS "value"
FROM WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT
WHERE "country_name" = 'Russian Federation'
  AND "indicator_name" ILIKE '%Debt%'
  AND "value" IS NOT NULL
GROUP BY "indicator_name"
ORDER BY "value" DESC NULLS LAST
LIMIT 3;