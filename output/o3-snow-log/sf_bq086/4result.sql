/*  Percentage of each country's population that had been cumulatively confirmed
    with COVID-19 by 30 June 2020                               */

SELECT
    c."country_name",
    c."iso_3166_1_alpha_3"                              AS "country_code",
    c."cumulative_confirmed",
    p."year_2018"                                       AS "population_2018",
    ROUND( (c."cumulative_confirmed" / NULLIF(p."year_2018",0)) * 100 , 4 )
                                                       AS "percent_confirmed_population"
FROM COVID19_OPEN_WORLD_BANK.COVID19_OPEN_DATA.COVID19_OPEN_DATA            AS c
JOIN COVID19_OPEN_WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY AS p
      ON p."country_code" = c."iso_3166_1_alpha_3"
WHERE c."aggregation_level" = 0
  AND c."date"             = '2020-06-30'
  AND c."cumulative_confirmed" IS NOT NULL
  AND p."year_2018"           IS NOT NULL
ORDER BY "percent_confirmed_population" DESC NULLS LAST;