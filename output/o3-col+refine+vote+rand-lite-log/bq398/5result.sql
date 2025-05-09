-- Top three debt indicators for Russia based on their highest recorded values
WITH indicator_max AS (
  SELECT
    indicator_name,
    indicator_code,
    MAX(value) AS max_value
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE country_code = 'RUS'
    AND value IS NOT NULL              -- ignore blank entries
  GROUP BY indicator_name, indicator_code
)
SELECT
  indicator_name,
  indicator_code,
  max_value
FROM indicator_max
ORDER BY max_value DESC
LIMIT 3;