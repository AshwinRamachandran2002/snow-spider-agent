-- Top 10 countries by total long‑term external debt (current US$),
-- excluding countries that do not have a region assigned
WITH long_term_codes AS (      -- 1. identify “long‑term external debt” indicators
  SELECT DISTINCT series_code
  FROM `bigquery-public-data.world_bank_intl_debt.series_summary`
  WHERE LOWER(indicator_name) LIKE '%external debt%'
    AND LOWER(indicator_name) LIKE '%long-term%'
    AND LOWER(indicator_name) LIKE '%current us$%'
),
aggregated_debt AS (           -- 2. aggregate debt over all years for each country
  SELECT
    d.country_code,
    ANY_VALUE(d.country_name) AS country_name,
    SUM(d.value)              AS total_long_term_debt
  FROM `bigquery-public-data.world_bank_intl_debt.international_debt` AS d
  JOIN long_term_codes                         AS c
    ON d.indicator_code = c.series_code
  WHERE d.value IS NOT NULL
  GROUP BY d.country_code
)
SELECT                          -- 3. keep only countries with a defined region
  a.country_name,
  a.total_long_term_debt
FROM aggregated_debt AS a
JOIN `bigquery-public-data.world_bank_intl_debt.country_summary` AS cs
  ON a.country_code = cs.country_code
WHERE cs.region IS NOT NULL
ORDER BY a.total_long_term_debt DESC, a.country_name
LIMIT 10;