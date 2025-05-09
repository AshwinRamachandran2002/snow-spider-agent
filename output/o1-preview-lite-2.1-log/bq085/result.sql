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