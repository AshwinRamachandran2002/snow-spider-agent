-- Count distinct debt indicators for Russia where the recorded value is exactly zero (excluding NULLs)
SELECT COUNT(DISTINCT indicator_code) AS num_indicators_with_zero
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS'
  AND value = 0;