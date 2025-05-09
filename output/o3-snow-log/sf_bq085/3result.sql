WITH population_2020 AS (   -- total 2020 population per country
    SELECT
        h."country_name",
        SUM(h."value") AS "population_2020"
    FROM COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION h
    WHERE h."indicator_name" = 'Population, total'
      AND h."year" = 2020
      AND h."country_name" IN ('United States', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
    GROUP BY h."country_name"
),
confirmed_2020_04_20 AS (   -- confirmed cases on 20-Apr-2020 per country
    SELECT
        c."country_or_region"                          AS "country_name",
        SUM(CAST(c."_4_20_20" AS NUMBER))              AS "confirmed_cases_2020_04_20"
    FROM COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.CONFIRMED_CASES c
    WHERE c."country_or_region" IN ('United States', 'France', 'China', 'Italy', 'Spain', 'Germany', 'Iran')
    GROUP BY c."country_or_region"
)
SELECT
    p."country_name"                                           AS "country",
    c."confirmed_cases_2020_04_20",
    ROUND( (c."confirmed_cases_2020_04_20" / p."population_2020") * 100000 , 4)  AS "cases_per_100k"
FROM population_2020 p
JOIN confirmed_2020_04_20 c
  ON c."country_name" = p."country_name"
ORDER BY p."country_name";