SELECT
  indicator_name AS debt_indicator,
  ROUND(MAX(value), 4) AS debt_value_usd
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS'
GROUP BY indicator_name
ORDER BY debt_value_usd DESC, debt_indicator
LIMIT 3;