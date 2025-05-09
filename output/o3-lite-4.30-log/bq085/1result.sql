WITH mapping AS (
  SELECT 'US'      AS covid_name, 'United States' AS country UNION ALL
  SELECT 'France', 'France'                       UNION ALL
  SELECT 'China',  'China'                        UNION ALL
  SELECT 'Italy',  'Italy'                        UNION ALL
  SELECT 'Spain',  'Spain'                        UNION ALL
  SELECT 'Germany','Germany'                      UNION ALL
  SELECT 'Iran',   'Iran'
),
covid AS (
  SELECT
    m.country,
    SUM(s.confirmed) AS confirmed_cases_2020_04_20
  FROM `bigquery-public-data.covid19_jhu_csse.summary` AS s
  JOIN mapping AS m
    ON s.country_region = m.covid_name
  WHERE s.date = DATE '2020-04-20'
  GROUP BY m.country
),
pop AS (
  SELECT
    CASE
      WHEN country_name = 'Iran, Islamic Rep.' THEN 'Iran'
      ELSE country_name
    END AS country,
    SUM(value) AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE year = 2020
    AND indicator_code = 'SP.POP.TOTL'
    AND country_name IN ('United States','France','China','Italy','Spain','Germany','Iran, Islamic Rep.')
  GROUP BY country
)
SELECT
  c.country,
  c.confirmed_cases_2020_04_20 AS `confirmed_cases_2020-04-20`,
  ROUND((c.confirmed_cases_2020_04_20 / p.population_2020) * 100000, 4) 
       AS cases_per_100k_population_2020
FROM covid AS c
JOIN pop   AS p USING (country)
ORDER BY c.country;