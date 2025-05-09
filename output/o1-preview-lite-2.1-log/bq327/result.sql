SELECT COUNT(DISTINCT indicator_code) AS Number_of_Debt_Indicators_with_Value_Zero
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS' 
  AND value = 0 
  AND value IS NOT NULL
  AND indicator_code IS NOT NULL;