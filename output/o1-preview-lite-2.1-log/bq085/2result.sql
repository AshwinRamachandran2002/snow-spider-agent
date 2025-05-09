SELECT 
    s.country_region AS Country,
    SUM(s.confirmed) AS Total_confirmed_cases,
    ROUND((SUM(s.confirmed) / p.value) * 100000, 4) AS Cases_per_100000_people
FROM `bigquery-public-data.covid19_jhu_csse.summary` AS s
JOIN `bigquery-public-data.world_bank_wdi.indicators_data` AS p
  ON (
      s.country_region = p.country_name
      OR (s.country_region = 'US' AND p.country_name = 'United States')
      OR (s.country_region = 'Iran' AND p.country_name = 'Iran, Islamic Rep.')
  )
WHERE s.date = '2020-04-20'
  AND s.country_region IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
  AND p.indicator_code = 'SP.POP.TOTL'
  AND p.year = 2020
GROUP BY Country, p.value
ORDER BY Country;