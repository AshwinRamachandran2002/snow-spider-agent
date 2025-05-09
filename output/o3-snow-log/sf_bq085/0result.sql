WITH cases AS (
    SELECT
        CASE 
            WHEN "country_region" = 'US' THEN 'United States'
            ELSE "country_region"
        END                                              AS "country",
        SUM("confirmed")                                 AS "total_confirmed_cases"
    FROM COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.SUMMARY
    WHERE "date" = '2020-04-20'
      AND "country_region" IN ('US', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
    GROUP BY
        CASE 
            WHEN "country_region" = 'US' THEN 'United States'
            ELSE "country_region"
        END
),
population AS (
    SELECT
        "country_name"                                   AS "country",
        SUM("value")                                     AS "population_2020"
    FROM COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "year" = 2020
      AND LOWER("indicator_name") LIKE '%total%'
      AND "country_name" IN ('United States', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
    GROUP BY
        "country_name"
)
SELECT
    c."country",
    c."total_confirmed_cases",
    p."population_2020",
    (c."total_confirmed_cases" / p."population_2020") * 100000   AS "cases_per_100k"
FROM cases      c
JOIN population p
  ON c."country" = p."country"
ORDER BY c."country";