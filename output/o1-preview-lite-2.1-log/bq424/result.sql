SELECT
  id.country_name AS Country,
  SUM(id.value) AS Total_Long_Term_External_Debt
FROM
  `bigquery-public-data.world_bank_wdi.indicators_data` AS id
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
ON
  id.country_code = cs.country_code
WHERE
  id.indicator_code = 'DT.DOD.DLXF.CD'
  AND cs.region IS NOT NULL
  AND TRIM(cs.region) != ''
  AND LENGTH(cs.country_code) = 3
GROUP BY
  id.country_name
ORDER BY
  Total_Long_Term_External_Debt DESC
LIMIT 10;