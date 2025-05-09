-- Top three debt‑related indicators for Russia with the highest recorded values
WITH russian_debt AS (
  SELECT
    indicator_name,
    indicator_code,
    MAX(value) AS max_value_usd  -- highest recorded figure (all years, in the series' units)
  FROM
    `bigquery-public-data.world_bank_intl_debt.international_debt`
  WHERE
    country_code = 'RUS'                     -- Russia
    AND value IS NOT NULL                    -- keep only existing observations
    AND LOWER(indicator_name) LIKE '%debt%'  -- keep debt‑related indicators
  GROUP BY
    indicator_name,
    indicator_code
)
SELECT
  indicator_name,
  indicator_code,
  max_value_usd
FROM
  russian_debt
ORDER BY
  max_value_usd DESC
LIMIT 3;