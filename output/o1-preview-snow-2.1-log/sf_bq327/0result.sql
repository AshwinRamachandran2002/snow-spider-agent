SELECT COUNT(DISTINCT "indicator_name") AS "Number_of_Debt_Indicators"
FROM WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT
WHERE "country_name" = 'Russian Federation'
  AND "value" = 0
  AND "value" IS NOT NULL;