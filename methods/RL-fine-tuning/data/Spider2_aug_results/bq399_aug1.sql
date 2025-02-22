-- Task: Find the average crude birth rate during the 1980s for each high-income country, along with their country name and region.
SELECT 
  data.country_code, 
  country_data.country,
  country_data.region,
  AVG(value) AS avg_birth_rate
FROM 
  `bigquery-public-data.world_bank_wdi.indicators_data` AS data 
LEFT JOIN 
  (
    SELECT 
      country_code, 
      short_name AS country,
      region, 
      income_group 
    FROM 
      `bigquery-public-data.world_bank_wdi.country_summary`
  ) AS country_data
ON 
  data.country_code = country_data.country_code
WHERE 
  indicator_code = "SP.DYN.CBRT.IN" -- Birth Rate
  AND EXTRACT(YEAR FROM PARSE_DATE('%Y', CAST(year AS STRING))) BETWEEN 1980 AND 1989 -- 1980s
  AND country_data.income_group = "High income" -- High-income group
GROUP BY 
  data.country_code, 
  country_data.country,
  country_data.region
ORDER BY 
  avg_birth_rate DESC;