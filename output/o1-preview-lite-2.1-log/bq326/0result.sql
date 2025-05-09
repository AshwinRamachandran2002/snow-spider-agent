SELECT
  COUNT(*) AS Number_of_Countries
FROM (
  SELECT
    pop.country_code,
    pop.country,
    ((pop.year_2018 - pop.year_2017) / NULLIF(pop.year_2017, 0)) * 100 AS population_growth_percentage,
    ((health.value_2018 - health.value_2017) / NULLIF(health.value_2017, 0)) * 100 AS health_expenditure_growth_percentage
  FROM `bigquery-public-data.world_bank_global_population.population_by_country` AS pop
  JOIN (
    SELECT
      country_code,
      SUM(CASE WHEN year = 2017 THEN value ELSE NULL END) AS value_2017,
      SUM(CASE WHEN year = 2018 THEN value ELSE NULL END) AS value_2018
    FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE indicator_code = 'SH.XPD.CHEX.PP.CD' AND year IN (2017, 2018)
    GROUP BY country_code
  ) AS health
  ON pop.country_code = health.country_code
  WHERE pop.year_2017 IS NOT NULL AND pop.year_2018 IS NOT NULL AND
        health.value_2017 IS NOT NULL AND health.value_2018 IS NOT NULL
) AS combined
WHERE combined.population_growth_percentage > 1 AND combined.health_expenditure_growth_percentage > 1