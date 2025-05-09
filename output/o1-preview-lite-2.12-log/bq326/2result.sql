SELECT COUNT(*) AS Number_of_Countries
FROM (
  SELECT pop.country_code
  FROM `bigquery-public-data.world_bank_global_population.population_by_country` AS pop
  JOIN (
    SELECT country_code,
      SUM(CASE WHEN year = 2017 THEN value END) AS exp_2017,
      SUM(CASE WHEN year = 2018 THEN value END) AS exp_2018
    FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE indicator_code = 'SH.XPD.CHEX.PP.CD'
      AND year IN (2017, 2018)
    GROUP BY country_code
    HAVING exp_2017 IS NOT NULL AND exp_2018 IS NOT NULL AND exp_2017 > 0
  ) AS health
  ON pop.country_code = health.country_code
  WHERE ((pop.year_2018 - pop.year_2017) / CAST(pop.year_2017 AS FLOAT64)) * 100 > 1
    AND ((health.exp_2018 - health.exp_2017) / health.exp_2017) * 100 > 1
)