WITH cases AS (
  -- total confirmed cases on 20 Apr 2020
  SELECT
    country_or_region AS country,
    SUM(CAST(`_4_20_20` AS INT64)) AS confirmed
  FROM `bigquery-public-data.covid19_jhu_csse.confirmed_cases`
  WHERE country_or_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country
),
pops AS (
  -- 2020 population totals (sum of all relevant rows)
  SELECT
    CASE
      WHEN country_name = 'United States'       THEN 'US'
      WHEN country_name = 'France'              THEN 'France'
      WHEN country_name = 'China'               THEN 'China'
      WHEN country_name = 'Italy'               THEN 'Italy'
      WHEN country_name = 'Spain'               THEN 'Spain'
      WHEN country_name = 'Germany'             THEN 'Germany'
      WHEN country_name = 'Iran, Islamic Rep.'  THEN 'Iran'
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
  c.confirmed,
  p.population_2020,
  ROUND(c.confirmed / p.population_2020 * 100000, 4) AS cases_per_100k
FROM cases AS c
JOIN pops  AS p
USING (country)
ORDER BY country;