WITH population_2020 AS (
    SELECT
        "country_name"                                                         AS "country",
        SUM("value")                                                           AS "population_2020_total"
    FROM COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "country_name" IN ('United States','France','China','Italy','Spain','Germany','Iran')
      AND "year" = 2020
      AND "indicator_name" ILIKE '%population, total%'
    GROUP BY "country_name"
),
cases_2020_04_20 AS (
    SELECT
        CASE 
            WHEN "country_region" = 'US' THEN 'United States'
            ELSE "country_region"
        END                                                                     AS "country",
        SUM("confirmed")                                                        AS "total_confirmed_cases"
    FROM COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.SUMMARY
    WHERE "country_region" IN ('US','France','China','Italy','Spain','Germany','Iran')
      AND "date" = '2020-04-20'
    GROUP BY CASE 
                 WHEN "country_region" = 'US' THEN 'United States'
                 ELSE "country_region"
             END
)
SELECT
    p."country",
    c."total_confirmed_cases",
    p."population_2020_total",
    (c."total_confirmed_cases" / p."population_2020_total") * 100000            AS "cases_per_100k_population"
FROM population_2020 p
JOIN cases_2020_04_20 c
  ON p."country" = c."country"
ORDER BY c."total_confirmed_cases" DESC NULLS LAST;