-- Total confirmed COVID-19 cases on 2020-04-20
-- plus cases per 100,000 people (2020 population)
WITH cases AS (
  SELECT
    CASE
      WHEN country_region = 'US' THEN 'United States'
      ELSE country_region
    END                          AS country,
    SUM(confirmed)               AS confirmed_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE date = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country
),
pop AS (
  SELECT
    country_name                 AS country,
    SUM(value)                   AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_name = 'Population, total'
    AND year = 2020
    AND country_name IN ('United States','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_name
)
SELECT
  c.country,
  c.confirmed_cases,
  p.population_2020,
  ROUND(c.confirmed_cases * 100000.0 / p.population_2020 , 2) AS cases_per_100k
FROM cases c
JOIN pop   p USING (country)
ORDER BY cases_per_100k DESC;