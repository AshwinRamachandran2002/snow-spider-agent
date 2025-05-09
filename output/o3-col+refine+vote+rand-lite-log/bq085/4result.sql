/*  Confirmed cases on 20-Apr-2020 and cases per 100 000 population
    for the United States, France, China, Italy, Spain, Germany, and Iran */
WITH cases AS (
  SELECT
    `country_region`,
    SUM(`confirmed`) AS total_cases
  FROM `bigquery-public-data.covid19_jhu_csse.summary`
  WHERE `date` = '2020-04-20'
    AND `country_region` IN ('US','France','China','Italy','Spain','Germany','Iran')
  GROUP BY `country_region`
),
pop AS (
  SELECT
    CASE
      WHEN `country_name` = 'United States' THEN 'US'
      ELSE `country_name`
    END AS country_region,
    SUM(`value`) AS population_2020
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE `indicator_name` = 'Population, total'
    AND `year` = 2020
    AND `country_name` IN ('United States','France','China','Italy','Spain','Germany','Iran')
  GROUP BY country_region
)
SELECT
  c.`country_region`                                   AS country,
  c.total_cases                                        AS confirmed_cases_2020_04_20,
  p.population_2020,
  ROUND(100000 * c.total_cases / p.population_2020, 2) AS cases_per_100k
FROM cases AS c
JOIN pop   AS p
ON  c.`country_region` = p.`country_region`
ORDER BY country;