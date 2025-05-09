SELECT
  COUNT(DISTINCT indicator_code) AS zero_value_debt_indicators_for_russia
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'          -- Russia
  AND value = 0                 -- value exactly zero (NULLs automatically excluded)