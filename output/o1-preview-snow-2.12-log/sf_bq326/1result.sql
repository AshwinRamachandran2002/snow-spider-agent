SELECT COUNT(*) AS "Number_of_Countries"
FROM (
  SELECT p."country_code"
  FROM WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY p
  INNER JOIN (
    SELECT h."country_code",
           (
             (
               SUM(CASE WHEN h."year" = 2018 THEN h."value" END) -
               SUM(CASE WHEN h."year" = 2017 THEN h."value" END)
             ) / SUM(CASE WHEN h."year" = 2017 THEN h."value" END) * 100
           ) AS "health_expenditure_growth_pct"
    FROM WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION h
    WHERE h."indicator_name" = 'Current health expenditure per capita, PPP (current international $)'
      AND h."year" IN (2017, 2018)
    GROUP BY h."country_code"
  ) h ON p."country_code" = h."country_code"
  WHERE (
    (p."year_2018" - p."year_2017") / p."year_2017" * 100
  ) > 1
    AND h."health_expenditure_growth_pct" > 1
) sub;