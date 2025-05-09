SELECT
  indicator_name,
  indicator_code,
  MAX(value) AS max_debt_value
FROM
  `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE
  country_code = 'RUS'                -- Russia
  AND value IS NOT NULL               -- exclude missing numbers
  AND LOWER(indicator_name) LIKE '%debt%'   -- keep only debt‑related indicators
GROUP BY
  indicator_name,
  indicator_code
ORDER BY
  max_debt_value DESC
LIMIT 3;