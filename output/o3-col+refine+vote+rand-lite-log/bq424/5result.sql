-- Top 10 countries by total long-term external debt (current US$),
-- excluding aggregate “countries” that have no region assigned
SELECT
  c.short_name AS country,
  SUM(IFNULL(d.value, 0)) AS total_long_term_external_debt_usd
FROM `bigquery-public-data.world_bank_intl_debt.international_debt` AS d
JOIN `bigquery-public-data.world_bank_intl_debt.country_summary`        AS c
  ON d.country_code = c.country_code
WHERE d.indicator_code = 'DT.DOD.DLXF.CD'      -- long-term external debt stocks (current US$)
  AND c.region IS NOT NULL                     -- keep only real countries (region present)
  AND TRIM(c.region) <> ''
GROUP BY country
ORDER BY total_long_term_external_debt_usd DESC
LIMIT 10;