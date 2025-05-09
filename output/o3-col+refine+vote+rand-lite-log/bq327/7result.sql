-- How many distinct debt indicators for Russia ever report a value of 0 (excluding NULLs)?
SELECT
  COUNT(DISTINCT indicator_code) AS num_zero_debt_indicators
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS'
  AND value = 0;