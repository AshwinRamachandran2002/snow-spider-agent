SELECT COUNT(DISTINCT `indicator_code`) AS zero_valued_indicators_for_russia
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE `country_code` = 'RUS'
  AND `value` = 0;