SELECT COUNT(DISTINCT p."country_code") AS "Number_of_countries"
FROM "WORLD_BANK"."WORLD_BANK_GLOBAL_POPULATION"."POPULATION_BY_COUNTRY" p
JOIN (
  SELECT h2018."country_code"
  FROM "WORLD_BANK"."WORLD_BANK_HEALTH_POPULATION"."HEALTH_NUTRITION_POPULATION" h2018
  JOIN "WORLD_BANK"."WORLD_BANK_HEALTH_POPULATION"."HEALTH_NUTRITION_POPULATION" h2017
    ON h2018."country_code" = h2017."country_code" 
    AND h2018."indicator_name" = h2017."indicator_name"
  WHERE h2018."indicator_name" = 'Current health expenditure per capita, PPP (current international $)'
    AND h2018."year" = 2018
    AND h2017."year" = 2017
    AND h2017."value" IS NOT NULL
    AND h2017."value" > 0
    AND h2018."value" IS NOT NULL
    AND ((h2018."value" - h2017."value") / h2017."value") > 0.01
) h ON p."country_code" = h."country_code"
WHERE p."year_2017" IS NOT NULL
  AND p."year_2017" > 0
  AND p."year_2018" IS NOT NULL
  AND ((p."year_2018" - p."year_2017") / p."year_2017") > 0.01;