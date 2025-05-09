-- Top three debt indicators for Russia by their highest recorded value
WITH max_per_indicator AS (
  SELECT
    indicator_code,
    indicator_name,
    MAX(value) AS max_value
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE country_code = 'RUS'
  GROUP BY indicator_code, indicator_name
),
ranked AS (
  SELECT
    ROW_NUMBER() OVER (ORDER BY max_value DESC) AS rank,
    indicator_name,
    indicator_code,
    max_value
  FROM max_per_indicator
)
SELECT *
FROM ranked
ORDER BY rank
LIMIT 3;