-- Task: List all distinct debt indicator codes for Russia that have a value of 0, excluding NULL values.
SELECT DISTINCT indicator_code
FROM `bigquery-public-data.world_bank_intl_debt.international_debt`
WHERE country_code = 'RUS' 
  AND value = 0 
  AND value IS NOT NULL
  AND indicator_code IS NOT NULL;