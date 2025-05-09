SELECT COUNT(*) AS Number_of_Countries
FROM (
  SELECT p.country_code
  FROM (
    SELECT country_code,
      ((year_2018 - year_2017) / year_2017) * 100 AS population_growth_percent
    FROM `bigquery-public-data.world_bank_global_population.population_by_country`
    WHERE year_2017 IS NOT NULL AND year_2017 != 0
      AND year_2018 IS NOT NULL
  ) AS p
  INNER JOIN (
    SELECT country_code,
      ((expenditure_2018 - expenditure_2017) / expenditure_2017) * 100 AS health_expenditure_growth_percent
    FROM (
      SELECT country_code,
        SUM(CASE WHEN year = 2017 THEN value END) AS expenditure_2017,
        SUM(CASE WHEN year = 2018 THEN value END) AS expenditure_2018
      FROM `bigquery-public-data.world_bank_health_population.health_nutrition_population`
      WHERE indicator_name = 'Current health expenditure per capita, PPP (current international $)'
        AND year IN (2017, 2018)
      GROUP BY country_code
    )
    WHERE expenditure_2017 IS NOT NULL AND expenditure_2017 != 0
      AND expenditure_2018 IS NOT NULL
  ) AS h ON p.country_code = h.country_code
  WHERE p.population_growth_percent > 1
    AND h.health_expenditure_growth_percent > 1
)