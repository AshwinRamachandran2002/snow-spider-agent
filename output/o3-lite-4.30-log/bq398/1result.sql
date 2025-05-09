SELECT
  indicator_name AS debt_indicator,
  FORMAT('%.4f', MAX(value)) AS debt_value_usd
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'
  AND value IS NOT NULL
GROUP BY
  debt_indicator
ORDER BY
  MAX(value) DESC,
  debt_indicator
LIMIT 3;