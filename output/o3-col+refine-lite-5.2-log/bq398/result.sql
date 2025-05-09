-- Top three debt indicators for Russia by their highest recorded values
SELECT
  indicator_code,
  indicator_name,
  MAX(value) AS highest_recorded_debt_value
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS'
  AND value IS NOT NULL
GROUP BY
  indicator_code,
  indicator_name
ORDER BY
  highest_recorded_debt_value DESC
LIMIT 3;