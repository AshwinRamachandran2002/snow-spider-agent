-- Task: Provide a report for the countries United States, France, China, Italy, Spain, Germany, and Iran, showing for each:
--       - The total number of confirmed COVID-19 cases as of April 20, 2020, from the `summary` table in the `bigquery-public-data.covid19_jhu_csse` dataset.
--       - The number of cases per 100,000 people, calculated using the total 2020 population from the World Bank data, specifically from the `indicators_data` table in the `bigquery-public-data.world_bank_wdi` dataset, using the indicator code `SP.POP.TOTL`.
--       Ensure proper matching of country names between datasets.
WITH country_mapping AS (
  SELECT 'US' AS country_region, 'United States' AS country_name UNION ALL
  SELECT 'France', 'France' UNION ALL
  SELECT 'China', 'China' UNION ALL
  SELECT 'Italy', 'Italy' UNION ALL
  SELECT 'Spain', 'Spain' UNION ALL
  SELECT 'Germany', 'Germany' UNION ALL
  SELECT 'Iran', 'Iran, Islamic Rep.'
)
SELECT 
  cm.country_region AS Country,
  SUM(cv.confirmed) AS Total_confirmed_cases,
  ROUND(SUM(cv.confirmed) / (pop.population / 100000), 4) AS Cases_per_100000_people
FROM 
  `bigquery-public-data.covid19_jhu_csse.summary` cv
JOIN 
  country_mapping cm ON cv.country_region = cm.country_region
JOIN 
  (
    SELECT country_name, value AS population
    FROM `bigquery-public-data.world_bank_wdi.indicators_data`
    WHERE indicator_code = 'SP.POP.TOTL' AND year = 2020
  ) pop ON cm.country_name = pop.country_name
WHERE 
  cv.date = '2020-04-20'
GROUP BY 
  cm.country_region, pop.population
ORDER BY 
  cm.country_region