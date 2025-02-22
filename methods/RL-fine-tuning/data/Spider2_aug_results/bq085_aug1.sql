-- Task: Provide the total number of confirmed COVID-19 cases as of April 20, 2020, for the United States, France, China, Italy, Spain, Germany, and Iran.
SELECT 
  cv.country_region AS Country,
  SUM(cv.confirmed) AS Total_confirmed_cases
FROM 
  `bigquery-public-data.covid19_jhu_csse.summary` cv
WHERE 
  cv.date = '2020-04-20'
  AND cv.country_region IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
GROUP BY 
  cv.country_region
ORDER BY 
  cv.country_region