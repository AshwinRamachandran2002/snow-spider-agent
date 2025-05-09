SELECT COUNT(*) AS "Number_of_Countries"
FROM (
    SELECT p."country_code"
    FROM "WORLD_BANK"."WORLD_BANK_GLOBAL_POPULATION"."POPULATION_BY_COUNTRY" p
    JOIN (
        SELECT "country_code",
               ((MAX(CASE WHEN "year" = 2018 THEN "value" END) -
                 MAX(CASE WHEN "year" = 2017 THEN "value" END)) /
                MAX(CASE WHEN "year" = 2017 THEN "value" END) * 100) AS "health_exp_growth_pct"
        FROM "WORLD_BANK"."WORLD_BANK_HEALTH_POPULATION"."HEALTH_NUTRITION_POPULATION"
        WHERE "indicator_name" = 'Current health expenditure per capita, PPP (current international $)'
          AND "year" IN (2017, 2018)
        GROUP BY "country_code"
        HAVING ((MAX(CASE WHEN "year" = 2018 THEN "value" END) -
                 MAX(CASE WHEN "year" = 2017 THEN "value" END)) /
                MAX(CASE WHEN "year" = 2017 THEN "value" END) * 100) > 1
    ) h ON p."country_code" = h."country_code"
    WHERE p."year_2017" IS NOT NULL AND p."year_2018" IS NOT NULL
      AND ((p."year_2018" - p."year_2017") / p."year_2017" * 100) > 1
) AS sub;