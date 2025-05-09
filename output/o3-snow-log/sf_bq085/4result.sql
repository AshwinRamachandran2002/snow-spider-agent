WITH cases_raw AS (   -- pull 20-Apr-2020 confirmed-case rows for the seven target countries
    SELECT
        CASE
            WHEN "country_or_region" ILIKE 'US'                THEN 'United States'
            WHEN "country_or_region" ILIKE 'United States%'    THEN 'United States'
            ELSE "country_or_region"
        END                                 AS "country",
        TRY_CAST("_4_20_20" AS NUMBER)      AS "confirmed"
    FROM COVID19_JHU_WORLD_BANK.COVID19_JHU_CSSE.CONFIRMED_CASES
    WHERE REGEXP_LIKE(
              "country_or_region",
              '^US$|United\\s*States|France|China|Italy|Spain|Germany|Iran',
              'i'
          )
),
cases AS (        -- sum confirmed cases per country
    SELECT
        "country",
        SUM("confirmed") AS "confirmed_20_apr_2020"
    FROM cases_raw
    GROUP BY "country"
),
pop_raw AS (      -- pull 2020 population rows for the same countries
    SELECT
        CASE
            WHEN "country_name" ILIKE 'United States%' THEN 'United States'
            WHEN "country_name" ILIKE 'Iran%'          THEN 'Iran'
            ELSE "country_name"
        END          AS "country",
        "value"      AS "population_value"
    FROM COVID19_JHU_WORLD_BANK.WORLD_BANK_HEALTH_POPULATION.HEALTH_NUTRITION_POPULATION
    WHERE "indicator_name" = 'Population, total'
      AND "year" = 2020
      AND REGEXP_LIKE(
              "country_name",
              'United\\s*States|France|China|Italy|Spain|Germany|Iran',
              'i'
          )
),
pop AS (          -- sum population values per country (handles any duplicate rows)
    SELECT
        "country",
        SUM("population_value") AS "population_2020"
    FROM pop_raw
    GROUP BY "country"
)
SELECT
    c."country",
    c."confirmed_20_apr_2020",
    p."population_2020",
    ROUND( (c."confirmed_20_apr_2020" / p."population_2020") * 100000 , 2 ) AS "cases_per_100k"
FROM cases c
JOIN pop p
  ON c."country" = p."country"
ORDER BY "cases_per_100k" DESC NULLS LAST;