-- Top three debt indicators for Russia by their highest recorded value
WITH rus_debt AS (
  SELECT
    indicator_name,
    indicator_code,
    MAX(value) AS max_value
  FROM
    `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE
    country_code = 'RUS'        -- Russia
    AND value IS NOT NULL       -- exclude missing data
  GROUP BY
    indicator_name,
    indicator_code
)
SELECT
  indicator_name,
  indicator_code,
  max_value
FROM
  rus_debt
ORDER BY
  max_value DESC
LIMIT 3;