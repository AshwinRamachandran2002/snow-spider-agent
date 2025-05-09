-- Top 10 countries by cumulative long-term external debt (current US$)
SELECT
  d.country_code,
  c.short_name AS country,
  c.region,
  SUM(d.value) AS total_long_term_debt_usd
FROM `bigquery-public-data.world_bank_intl_debt.international_debt` AS d
JOIN `bigquery-public-data.world_bank_intl_debt.country_summary`  AS c
  ON d.country_code = c.country_code
WHERE d.indicator_code = 'DT.DOD.DLXF.CD'      -- Long-term external debt, current US$
  AND c.region IS NOT NULL                     -- exclude aggregates with unspecified region
GROUP BY d.country_code, c.short_name, c.region
ORDER BY total_long_term_debt_usd DESC
LIMIT 10;