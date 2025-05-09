WITH population_2020 AS (   -- total 2020 population per country
    SELECT
        "country_name"                            AS "country",
        SUM("value")                              AS "population_2020"
    FROM COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "indicator_name" = 'Population, total'
      AND "year"          = 2020
      AND "country_name" IN ('United States', 'France', 'China',
                             'Italy', 'Spain', 'Germany', 'Iran')
    GROUP BY "country_name"
),
cases_20apr2020 AS (        -- confirmed cases as of 20-Apr-2020
    SELECT
        "country_or_region"                      AS "country",
        SUM(TO_NUMBER("_4_20_20"))               AS "total_confirmed_2020_04_20"
    FROM COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.CONFIRMED_CASES
    WHERE "country_or_region" IN ('United States', 'France', 'China',
                                  'Italy', 'Spain', 'Germany', 'Iran')
    GROUP BY "country_or_region"
)
SELECT
    c."country",
    c."total_confirmed_2020_04_20",
    p."population_2020",
    ROUND( (c."total_confirmed_2020_04_20" / p."population_2020") * 100000 , 2)
        AS "cases_per_100k"
FROM cases_20apr2020 c
JOIN population_2020 p
  ON p."country" = c."country"
ORDER BY c."country";