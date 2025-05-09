/*  Total confirmed COVID-19 cases on 2020-04-20
    and cases per 100 000 inhabitants for
    the United States, France, China, Italy,
    Spain, Germany and Iran                                    */

WITH case_counts AS (
  SELECT
    country_region,
    SUM(confirmed) AS total_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE `date` = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_region
),
pop_2020 AS (
  SELECT
    country_name,
    SUM(value) AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_name = 'Population, total'
    AND year = 2020
    AND country_name IN ('United States',
                         'France',
                         'China',
                         'Italy',
                         'Spain',
                         'Germany',
                         'Iran, Islamic Rep.')
  GROUP BY country_name
)
SELECT
  CASE
    WHEN c.country_region = 'US'   THEN 'United States'
    WHEN c.country_region = 'Iran' THEN 'Iran'
    ELSE c.country_region
  END                                   AS country,
  c.total_cases,
  p.population_2020,
  ROUND(c.total_cases / p.population_2020 * 100000, 2) AS cases_per_100k
FROM case_counts AS c
JOIN pop_2020  AS p
      ON (  (c.country_region = 'US'   AND p.country_name = 'United States')
         OR (c.country_region = 'Iran' AND p.country_name = 'Iran, Islamic Rep.')
         OR (c.country_region NOT IN ('US','Iran') AND c.country_region = p.country_name) )
ORDER BY country;