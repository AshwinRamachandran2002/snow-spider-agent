SELECT
  COUNT(DISTINCT indicator_code) AS zero_debt_indicators
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'        -- Russia
  AND value = 0               -- value equal to 0 (NULLs automatically excluded)