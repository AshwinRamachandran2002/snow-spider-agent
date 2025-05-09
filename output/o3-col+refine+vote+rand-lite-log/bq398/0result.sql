-- Top three debt indicators for Russia based on the highest recorded debt value
WITH max_values AS (
  SELECT
    indicator_code,
    MAX(value) AS max_value
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE country_code = 'RUS'
  GROUP BY indicator_code
)

SELECT
  i.indicator_name,
  m.indicator_code,
  m.max_value AS highest_debt_value
FROM max_values AS m
JOIN (
  SELECT DISTINCT indicator_code, indicator_name
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
) AS i
ON m.indicator_code = i.indicator_code
ORDER BY m.max_value DESC
LIMIT 3;