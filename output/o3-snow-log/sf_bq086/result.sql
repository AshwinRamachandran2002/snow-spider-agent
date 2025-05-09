WITH
-- cumulative confirmed cases per country on 2020-06-30 (national level only)
"covid_totals" AS (
    SELECT
        "iso_3166_1_alpha_3"                    AS "iso3",
        SUM("cumulative_confirmed")             AS "cum_confirmed"
    FROM   COVID19_OPEN_WORLD_BANK.COVID19_OPEN_DATA."COVID19_OPEN_DATA"
    WHERE  "date" = '2020-06-30'
      AND  "aggregation_level" = 0             -- 0 = national level
    GROUP  BY "iso_3166_1_alpha_3"
),
-- 2018 population by country
"pop_2018" AS (
    SELECT
        "country"                              AS "country_name",
        "country_code"                         AS "iso3",
        "year_2018"                            AS "population_2018"
    FROM   COVID19_OPEN_WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION."POPULATION_BY_COUNTRY"
    WHERE  "year_2018" IS NOT NULL
)

SELECT
    p."country_name",
    p."iso3",
    c."cum_confirmed",
    p."population_2018",
    ROUND( (c."cum_confirmed" / p."population_2018") * 100, 4 ) 
        AS "percent_of_population_confirmed"
FROM   "pop_2018"  p
JOIN   "covid_totals" c
       ON p."iso3" = c."iso3"
ORDER  BY "percent_of_population_confirmed" DESC NULLS LAST;