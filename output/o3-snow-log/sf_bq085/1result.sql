WITH target_countries AS (      -- list of countries we need
    SELECT column1 AS "country" FROM VALUES
        ('United States'),
        ('France'),
        ('China'),
        ('Italy'),
        ('Spain'),
        ('Germany'),
        ('Iran')
),
-- total confirmed cases per country on 20-Apr-2020
cases AS (
    SELECT
        cc."country_or_region"          AS "country",
        SUM(cc."_4_20_20"::NUMBER)      AS "confirmed_cases"
    FROM COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.CONFIRMED_CASES cc
    JOIN target_countries tc
          ON cc."country_or_region" = tc."country"
    GROUP BY cc."country_or_region"
),
-- 2020 population (sum of all rows that belong to each country)
pop AS (
    SELECT
        hp."country_name"               AS "country",
        SUM(hp."value")                 AS "population_2020"
    FROM COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION hp
    JOIN target_countries tc
          ON hp."country_name" = tc."country"
    WHERE hp."indicator_name" = 'Population, total'
      AND hp."year" = 2020
    GROUP BY hp."country_name"
)
SELECT
    c."country",
    c."confirmed_cases",
    p."population_2020",
    ROUND( (c."confirmed_cases" / p."population_2020") * 100000, 2 ) AS "cases_per_100k"
FROM cases c
JOIN pop  p ON c."country" = p."country"
ORDER BY c."country";