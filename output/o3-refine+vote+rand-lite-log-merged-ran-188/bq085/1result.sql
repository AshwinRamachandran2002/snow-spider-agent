WITH confirmed AS (
  -- Total confirmed cases on 20-Apr-2020
  SELECT
    CASE WHEN country_region = 'US' THEN 'United States'
         ELSE country_region
    END AS country,
    SUM(confirmed) AS confirmed_total
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE date = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country
),
population AS (
  -- 2020 total population (sum of all relevant rows)
  SELECT
    CASE WHEN country_name = 'Iran, Islamic Rep.' THEN 'Iran'
         ELSE country_name
    END AS country,
    SUM(value) AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_name = 'Population, total'
    AND year = 2020
    AND country_name IN ('United States','France','China','Italy','Spain','Germany','Iran, Islamic Rep.')
  GROUP BY country
)
SELECT
  c.country,
  c.confirmed_total,
  p.population_2020,
  ROUND(c.confirmed_total / p.population_2020 * 100000, 2) AS cases_per_100k
FROM confirmed AS c
JOIN population AS p
USING (country)
ORDER BY c.country;