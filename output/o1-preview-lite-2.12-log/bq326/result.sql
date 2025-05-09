SELECT COUNT(*) AS `Number_of_Countries`
FROM (
  SELECT pg.`country_code`
  FROM (
    SELECT `country_code`,
      ((`year_2018` - `year_2017`) / CAST(`year_2017` AS FLOAT64)) * 100 AS `population_growth_percent`
    FROM `bigquery-public-data.world_bank_global_population.population_by_country`
    WHERE `year_2017` IS NOT NULL AND `year_2018` IS NOT NULL
  ) AS pg
  INNER JOIN (
    SELECT `country_code`,
      ((MAX(CASE WHEN `year` = 2018 THEN `value` END) - MAX(CASE WHEN `year` = 2017 THEN `value` END))
      / MAX(CASE WHEN `year` = 2017 THEN `value` END)) * 100 AS `health_expenditure_growth_percent`
    FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
    WHERE `indicator_code` = 'SH.XPD.CHEX.PP.CD' AND `year` IN (2017, 2018)
    GROUP BY `country_code`
    HAVING MAX(CASE WHEN `year` = 2017 THEN `value` END) IS NOT NULL
       AND MAX(CASE WHEN `year` = 2018 THEN `value` END) IS NOT NULL
  ) AS heg ON pg.`country_code` = heg.`country_code`
  WHERE pg.`population_growth_percent` > 1
    AND heg.`health_expenditure_growth_percent` > 1
)