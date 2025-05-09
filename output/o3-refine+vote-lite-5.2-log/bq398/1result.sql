-- Top three debt indicators for Russia with the highest recorded debt values
WITH russia_debt AS (
  SELECT
    indicator_name,
    indicator_code,
    MAX(value) AS max_debt_value
  FROM
    `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE
    country_code = 'RUS'       -- Russia
    AND value IS NOT NULL      -- ignore missing observations
  GROUP BY
    indicator_name,
    indicator_code
)
SELECT
  indicator_name,
  indicator_code,
  max_debt_value
FROM
  russia_debt
ORDER BY
  max_debt_value DESC
LIMIT 3;