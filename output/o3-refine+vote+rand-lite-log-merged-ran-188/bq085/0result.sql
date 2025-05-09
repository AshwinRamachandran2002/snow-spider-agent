WITH mapping AS (
  SELECT 'US'      AS covid_name, 'United States'      AS wb_name UNION ALL
  SELECT 'France',                  'France'                     UNION ALL
  SELECT 'China',                   'China'                      UNION ALL
  SELECT 'Italy',                   'Italy'                      UNION ALL
  SELECT 'Spain',                   'Spain'                      UNION ALL
  SELECT 'Germany',                 'Germany'                    UNION ALL
  SELECT 'Iran',                    'Iran, Islamic Rep.'
),
-- total confirmed-case counts as of 20-Apr-2020
cases AS (
  SELECT
    country_or_region AS covid_name,
    SUM(CAST(`_4_20_20` AS INT64)) AS confirmed_cases_20200420
  FROM `bigquery-public-data.covid19_jhu_csse.confirmed_cases`
  WHERE country_or_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_or_region
),
-- 2020 total population (sum in case multiple rows exist per country)
pops AS (
  SELECT
    country_name AS wb_name,
    SUM(value)   AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE year = 2020
    AND indicator_name = 'Population, total'
    AND country_name IN ('United States','France','China','Italy','Spain','Germany','Iran, Islamic Rep.')
  GROUP BY country_name
)

SELECT
  m.wb_name                                     AS country,
  c.confirmed_cases_20200420                    AS confirmed_cases_as_of_2020_04_20,
  p.population_2020,
  ROUND(100000 * c.confirmed_cases_20200420 / p.population_2020, 2)
                                                AS cases_per_100k_population
FROM mapping AS m
JOIN cases  AS c USING (covid_name)
JOIN pops   AS p USING (wb_name)
ORDER BY country;