WITH pop_growth AS (
    SELECT 
        "country_code",
        "country",
        (("year_2018" - "year_2017") * 100.0 / "year_2017") AS "population_growth_percent"
    FROM 
        WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY
    WHERE 
        "year_2017" IS NOT NULL AND "year_2018" IS NOT NULL
),
health_exp_growth AS (
    SELECT 
        h2017."country_code",
        h2017."country_name",
        ((h2018."value" - h2017."value") * 100.0 / h2017."value") AS "health_exp_growth_percent"
    FROM 
        WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION h2017
    JOIN 
        WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION h2018
    ON 
        h2017."country_code" = h2018."country_code" AND 
        h2017."indicator_code" = h2018."indicator_code"
    WHERE 
        h2017."indicator_name" = 'Current health expenditure per capita, PPP (current international $)'
        AND h2017."year" = 2017 
        AND h2018."year" = 2018
),
countries_both_growth AS (
    SELECT 
        p."country_code",
        p."country"
    FROM 
        pop_growth p
    JOIN 
        health_exp_growth h
    ON 
        p."country_code" = h."country_code"
    WHERE 
        p."population_growth_percent" > 1
            AND h."health_exp_growth_percent" > 1
)
SELECT COUNT(DISTINCT "country_code") AS "Number_of_countries"
FROM countries_both_growth;