/*  Confirmed COVID-19 cases on 20-Apr-2020 and cases-per-100k population
    for United States, France, China, Italy, Spain, Germany and Iran       */

WITH cte_cases AS (      -- total confirmed cases per country on 20-Apr-2020
    SELECT
        CASE
            WHEN "country_region" = 'US'   THEN 'United States'
            WHEN "country_region" = 'Iran' THEN 'Iran, Islamic Rep.'
            ELSE "country_region"
        END                                AS "country",
        SUM("confirmed")                   AS "confirmed_cases"
    FROM COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.SUMMARY
    WHERE "country_region" IN ('US','France','China','Italy','Spain','Germany','Iran')
      AND "date" = '2020-04-20'
    GROUP BY 1
),

cte_population AS (      -- 2020 total population per country (World Bank)
    SELECT
        "country_name"                     AS "country",
        SUM("value")                       AS "population_2020"
    FROM COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "indicator_name" = 'Population, total'
      AND "year" = 2020
      AND "country_name" IN ('United States','France','China','Italy',
                             'Spain','Germany','Iran, Islamic Rep.')
    GROUP BY "country_name"
)

SELECT
    c."country",
    c."confirmed_cases",
    p."population_2020",
    ROUND( (c."confirmed_cases" * 100000.0) / NULLIF(p."population_2020",0) , 4) AS "cases_per_100k"
FROM cte_cases      c
JOIN cte_population p ON c."country" = p."country"
ORDER BY "cases_per_100k" DESC NULLS LAST;