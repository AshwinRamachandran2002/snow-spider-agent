SELECT
  COUNT(DISTINCT pop.country_code) AS Number_of_Countries
FROM
  (
    SELECT
      country_code,
      ((year_2018 - year_2017) / year_2017) * 100 AS population_growth
    FROM
      `bigquery-public-data.world_bank_global_population.population_by_country`
    WHERE
      year_2017 IS NOT NULL
      AND year_2018 IS NOT NULL
      AND year_2017 > 0
      AND year_2018 > 0
  ) AS pop
JOIN
  (
    SELECT
      t1.country_code,
      ((t2.value - t1.value) / t1.value) * 100 AS expenditure_growth
    FROM
      `bigquery-public-data.world_bank_health_population.health_nutrition_population` t1
    JOIN
      `bigquery-public-data.world_bank_health_population.health_nutrition_population` t2
      ON t1.country_code = t2.country_code
      AND t1.indicator_code = t2.indicator_code
    WHERE
      t1.indicator_code = 'SH.XPD.CHEX.PP.CD'
      AND t1.year = 2017
      AND t2.year = 2018
      AND t1.value IS NOT NULL
      AND t2.value IS NOT NULL
      AND t1.value > 0
      AND t2.value > 0
  ) AS exp
ON
  pop.country_code = exp.country_code
WHERE
  pop.population_growth > 1
  AND exp.expenditure_growth > 1
;