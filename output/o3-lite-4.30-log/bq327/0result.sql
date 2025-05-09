SELECT COUNT(DISTINCT indicator_code) AS debt_indicator_zero_count
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS'
  AND value = 0;