SELECT COUNT(DISTINCT "indicator_code") AS zero_valued_debt_indicators
FROM WORLD_BANK.WORLD_BANK_INTL_DEBT.INTERNATIONAL_DEBT
WHERE "country_code" = 'RUS'
      AND "value" = 0;