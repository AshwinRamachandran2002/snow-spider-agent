-- Count distinct debt indicators for Russia that ever take the exact value 0 (ignoring NULLs)
SELECT
  COUNT(DISTINCT indicator_code) AS num_zero_valued_indicators
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'
  AND value = 0;