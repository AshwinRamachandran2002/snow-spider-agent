-- Count how many distinct debt indicators for Russia ever have a recorded value of 0
SELECT
  COUNT(DISTINCT indicator_code) AS zero_value_indicators
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'    -- Russia
  AND value = 0           -- exclude NULLs, keep only exact zeros
;