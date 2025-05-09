SELECT
  cs.short_name AS Country,
  ROUND(SUM(wdi.value), 4) AS Total_Long_Term_External_Debt
FROM
  `bigquery-public-data.world_bank_wdi.indicators_data` AS wdi
JOIN
  `bigquery-public-data.world_bank_wdi.country_summary` AS cs
    ON wdi.country_code = cs.country_code
WHERE
  LOWER(wdi.indicator_name) LIKE '%external debt stocks, long-term%'
  AND cs.region IS NOT NULL
  AND cs.region != ''
  AND wdi.value IS NOT NULL
  AND wdi.year = (
    SELECT
      MAX(year)
    FROM
      `bigquery-public-data.world_bank_wdi.indicators_data`
    WHERE
      LOWER(indicator_name) LIKE '%external debt stocks, long-term%'
  )
GROUP BY
  cs.short_name
ORDER BY
  Total_Long_Term_External_Debt DESC
LIMIT
  10;