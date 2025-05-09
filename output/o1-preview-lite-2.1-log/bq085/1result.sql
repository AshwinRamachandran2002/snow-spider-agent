SELECT
  s.country_region AS Country,
  SUM(s.confirmed) AS Total_confirmed_cases,
  ROUND((SUM(s.confirmed) / MAX(p.value)) * 100000, 4) AS Cases_per_100000_people
FROM `bigquery-public-data.covid19_jhu_csse.summary` AS s
JOIN `bigquery-public-data.world_bank_wdi.indicators_data` AS p
  ON (
    CASE
      WHEN s.country_region = 'US' THEN 'United States'
      WHEN s.country_region = 'Iran' THEN 'Iran, Islamic Rep.'
      ELSE s.country_region
    END = p.country_name
  )
WHERE s.date = '2020-04-20'
  AND s.country_region IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
  AND s.confirmed IS NOT NULL
  AND p.indicator_code = 'SP.POP.TOTL'
  AND p.year = 2020
  AND p.value IS NOT NULL
GROUP BY Country
ORDER BY Country;