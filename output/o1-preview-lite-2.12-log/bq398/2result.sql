SELECT 
  indicator_name AS Indicator_Name, 
  ROUND(value, 4) AS Total_Debt_Value_USD
FROM `bigquery-public-data.world_bank_wdi.indicators_data`
WHERE country_name = 'Russian Federation' 
  AND value IS NOT NULL 
  AND year = (
    SELECT MAX(year)
    FROM `bigquery-public-data.world_bank_wdi.indicators_data`
    WHERE country_name = 'Russian Federation' AND value IS NOT NULL
  )
  AND LOWER(indicator_name) LIKE '%debt%'
ORDER BY value DESC
LIMIT 3;