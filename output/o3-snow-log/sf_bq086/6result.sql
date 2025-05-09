SELECT
       c."iso_3166_1_alpha_3"                                            AS "country_iso3",
       c."country_name",
       c."cumulative_confirmed",
       p."year_2018"                                                    AS "population_2018",
       (c."cumulative_confirmed" / p."year_2018") * 100                 AS "pct_pop_confirmed"
FROM   "COVID19_OPEN_WORLD_BANK"."COVID19_OPEN_DATA"."COVID19_OPEN_DATA"            c
JOIN   "COVID19_OPEN_WORLD_BANK"."WORLD_BANK_GLOBAL_POPULATION"."POPULATION_BY_COUNTRY" p
       ON  c."iso_3166_1_alpha_3" = p."country_code"
WHERE  c."aggregation_level" = 1               -- country level
  AND  c."date" = '2020-06-30'                 -- cut-off date
  AND  p."year_2018" IS NOT NULL               -- need population
ORDER BY "pct_pop_confirmed" DESC NULLS LAST;