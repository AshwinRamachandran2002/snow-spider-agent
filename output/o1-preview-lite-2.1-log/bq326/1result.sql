WITH pop AS (
  SELECT 
    country_code, 
    country, 
    year_2017 AS population_2017, 
    year_2018 AS population_2018
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2017 IS NOT NULL AND year_2018 IS NOT NULL
),
health_exp AS (
  SELECT 
    country_code, 
    MAX(CASE WHEN year = 2017 THEN value END) AS health_exp_2017,
    MAX(CASE WHEN year = 2018 THEN value END) AS health_exp_2018
  FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
  WHERE indicator_code = 'SH.XPD.CHEX.PP.CD' AND year IN (2017, 2018)
  GROUP BY country_code
  HAVING health_exp_2017 IS NOT NULL AND health_exp_2018 IS NOT NULL
),
combined AS (
  SELECT 
    pop.country_code, 
    pop.country,
    pop.population_2017, 
    pop.population_2018,
    health_exp.health_exp_2017, 
    health_exp.health_exp_2018,
    ROUND(((pop.population_2018 - pop.population_2017) / pop.population_2017) * 100, 4) AS population_pct_change,
    ROUND(((health_exp.health_exp_2018 - health_exp.health_exp_2017) / health_exp.health_exp_2017) * 100, 4) AS health_exp_pct_change
  FROM pop
  JOIN health_exp ON pop.country_code = health_exp.country_code
)
SELECT COUNT(*) AS Number_of_Countries
FROM combined
WHERE population_pct_change > 1 AND health_exp_pct_change > 1;