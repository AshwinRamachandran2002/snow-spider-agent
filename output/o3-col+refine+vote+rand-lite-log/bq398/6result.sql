SELECT
  indicator_name,
  indicator_code,
  MAX(value) AS highest_value
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS'
GROUP BY indicator_name, indicator_code
ORDER BY highest_value DESC
LIMIT 3;