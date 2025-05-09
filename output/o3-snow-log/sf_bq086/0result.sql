/*  Percentage of each country's population that had been cumulatively
    confirmed with COVID-19 by 30 June 2020                                  */

WITH covid AS (
    /* 1. Country–level cumulative confirmed cases on 2020-06-30            */
    SELECT
        "iso_3166_1_alpha_3"                       AS "iso3_code",
        MAX("cumulative_confirmed")                AS "cum_confirmed"
    FROM COVID19_OPEN_WORLD_BANK.COVID19_OPEN_DATA."COVID19_OPEN_DATA"
    WHERE "date" = '2020-06-30'
      AND "aggregation_level" = 0                  -- national totals only
      AND "iso_3166_1_alpha_3" IS NOT NULL
    GROUP BY "iso_3166_1_alpha_3"
),
pop AS (
    /* 2. 2018 population (latest complete year in this dataset)            */
    SELECT
        "country_code"                            AS "iso3_code",
        "country"                                 AS "country_name",
        "year_2018"                               AS "population_2018"
    FROM COVID19_OPEN_WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION."POPULATION_BY_COUNTRY"
    WHERE "year_2018" IS NOT NULL
)
SELECT
    pop."iso3_code",
    pop."country_name",
    covid."cum_confirmed",
    pop."population_2018",
    ROUND( (covid."cum_confirmed" / pop."population_2018") * 100 , 4)
        AS "percent_of_population_confirmed"
FROM pop
JOIN covid
  ON covid."iso3_code" = pop."iso3_code"
ORDER BY "percent_of_population_confirmed" DESC NULLS LAST;