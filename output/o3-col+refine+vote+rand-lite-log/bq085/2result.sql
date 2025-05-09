-- Total confirmed COVID-19 cases on 20-Apr-2020
-- and cases per 100 000 inhabitants for
-- United States, France, China, Italy, Spain, Germany, and Iran.
WITH cases AS (
  SELECT
    country_region,
    SUM(confirmed) AS total_confirmed
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE date = '2020-04-20'
    AND country_region IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_region
),
pop AS (
  SELECT
    country_name,
    SUM(value) AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE year = 2020
    AND indicator_name = 'Population, total'
    AND country_name IN ('United States','France','China','Italy','Spain',
                         'Germany','Iran, Islamic Rep.')
  GROUP BY country_name
),
xwalk AS (
  SELECT 'US' AS summary_country, 'United States'      AS country_name UNION ALL
  SELECT 'France',              'France'              UNION ALL
  SELECT 'China',               'China'               UNION ALL
  SELECT 'Italy',               'Italy'               UNION ALL
  SELECT 'Spain',               'Spain'               UNION ALL
  SELECT 'Germany',             'Germany'             UNION ALL
  SELECT 'Iran',                'Iran, Islamic Rep.'
)
SELECT
  x.country_name                         AS country,
  c.total_confirmed,
  p.population_2020,
  ROUND(100000 * c.total_confirmed / p.population_2020, 2) AS cases_per_100k
FROM xwalk AS x
JOIN cases AS c ON c.country_region = x.summary_country
JOIN pop   AS p ON p.country_name   = x.country_name
ORDER BY country;