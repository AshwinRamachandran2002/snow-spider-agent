SELECT
  indicator_name,
  indicator_code,
  MAX(value) AS highest_debt_value
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'
  AND value IS NOT NULL
GROUP BY
  indicator_name,
  indicator_code
ORDER BY
  highest_debt_value DESC
LIMIT 3;