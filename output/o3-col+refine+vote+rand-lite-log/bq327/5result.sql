SELECT
  COUNT(DISTINCT indicator_code) AS num_debt_indicators_zero_for_Russia
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'
  AND value = 0;