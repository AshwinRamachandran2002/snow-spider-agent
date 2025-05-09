SELECT
  indicator_name,
  ROUND(value, 4) AS Total_Debt_Value_USD
FROM
  `bigquery-public-data.world_bank_wdi.indicators_data`
WHERE
  country_name = 'Russian Federation'
  AND year = (
    SELECT MAX(year)
    FROM `bigquery-public-data.world_bank_wdi.indicators_data`
    WHERE country_name = 'Russian Federation'
      AND value IS NOT NULL
      AND LOWER(indicator_name) LIKE '%debt%'
  )
  AND value IS NOT NULL
  AND LOWER(indicator_name) LIKE '%debt%'
ORDER BY
  Total_Debt_Value_USD DESC
LIMIT 3;