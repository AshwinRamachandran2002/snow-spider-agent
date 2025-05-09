WITH russia_debt AS (
  SELECT
    indicator_name,
    indicator_code,
    MAX(value) AS max_debt_value
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE country_code = 'RUS'                         -- Russia
    AND indicator_code LIKE 'DT.%'                  -- keep debt‑related indicators
    AND value IS NOT NULL
  GROUP BY
    indicator_name,
    indicator_code
)
SELECT
  indicator_name,
  indicator_code,
  max_debt_value
FROM russia_debt
ORDER BY
  max_debt_value DESC
LIMIT 3;