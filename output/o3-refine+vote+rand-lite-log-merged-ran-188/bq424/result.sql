-- Top 10 countries by total long-term external debt stocks (current US$)
SELECT
  cs.short_name AS country_name,
  SUM(id.value) AS total_long_term_external_debt_usd
FROM `bigquery-public-data.world_bank_wdi.indicators_data`  AS id
JOIN `bigquery-public-data.world_bank_wdi.country_summary`  AS cs
  ON id.country_code = cs.country_code
WHERE id.indicator_code = 'DT.DOD.DLXF.CD'   -- External debt stocks, long-term (current US$)
  AND cs.region IS NOT NULL                  -- Exclude aggregates / undefined regions
  AND id.value IS NOT NULL                   -- Ignore missing values
GROUP BY cs.short_name
ORDER BY total_long_term_external_debt_usd DESC
LIMIT 10;