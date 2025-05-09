SELECT
  COUNT(DISTINCT indicator_code) AS num_debt_indicators_zero
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'
  AND value = 0;