SELECT id.country_name AS Country, SUM(id.value) AS Total_Long_Term_External_Debt
FROM `bigquery-public-data.world_bank_wdi.indicators_data` AS id
JOIN `bigquery-public-data.world_bank_wdi.country_summary` AS cs
  ON id.country_code = cs.country_code
WHERE id.indicator_name = 'External debt stocks, long-term (DOD, current US$)'
  AND id.value IS NOT NULL
  AND cs.region IS NOT NULL AND cs.region != ''
GROUP BY id.country_name
ORDER BY Total_Long_Term_External_Debt DESC
LIMIT 10;