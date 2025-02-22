-- Task: List the GDP values (constant 2015 US$), country names, and regions for all countries (limit to first 100 records).

WITH country_data AS (
  -- CTE for country descriptive data
  SELECT 
    country_code, 
    short_name AS country,
    region, 
    income_group 
  FROM 
    `bigquery-public-data.world_bank_wdi.country_summary`
),

gdp_data AS (
  -- Filter data to only include GDP values
  SELECT 
    data.country_code, 
    country,
    region,
    value AS gdp_value
  FROM 
    `bigquery-public-data.world_bank_wdi.indicators_data` data
  LEFT JOIN country_data
    ON data.country_code = country_data.country_code
  WHERE indicator_code = "NY.GDP.MKTP.KD" -- GDP Indicator
    AND country_data.region IS NOT NULL
    AND country_data.income_group IS NOT NULL
)

-- Select the country codes, country names, regions, and GDP values
SELECT 
  country_code,
  country,
  region,
  gdp_value
FROM gdp_data
LIMIT 100;