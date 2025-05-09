WITH confirmed AS (
  SELECT
    country_region AS country,
    SUM(confirmed) AS confirmed_cases_2020_04_20
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE date = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_region
),
population AS (
  SELECT
    CASE
      WHEN country_name = 'United States'      THEN 'US'
      WHEN country_name = 'Iran, Islamic Rep.' THEN 'Iran'
      ELSE country_name
    END AS country,
    SUM(value) AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SP.POP.TOTL'
    AND year = 2020
    AND country_name IN (
      'United States','France','China','Italy','Spain','Germany','Iran, Islamic Rep.'
    )
  GROUP BY country
)
SELECT
  c.country,
  c.confirmed_cases_2020_04_20,
  ROUND(c.confirmed_cases_2020_04_20 * 100000 / p.population_2020, 4) AS cases_per_100k_population_2020
FROM confirmed AS c
JOIN population AS p
  ON c.country = p.country
ORDER BY c.country;