SELECT
    c."iso_3166_1_alpha_3"                                                   AS "country_iso3",
    c."country_name",
    c."cumulative_confirmed",
    p."year_2018"                                                            AS "population_2018",
    ROUND( (c."cumulative_confirmed" / p."year_2018") * 100 , 4)             AS "percent_population_confirmed"
FROM
    "COVID19_OPEN_WORLD_BANK"."COVID19_OPEN_DATA"."COVID19_OPEN_DATA"        c
JOIN
    "COVID19_OPEN_WORLD_BANK"."WORLD_BANK_GLOBAL_POPULATION"."POPULATION_BY_COUNTRY" p
      ON p."country_code" = c."iso_3166_1_alpha_3"
WHERE
      c."aggregation_level"        = 0         -- country-level rows
  AND c."date"                     = '2020-06-30'
  AND c."cumulative_confirmed" IS NOT NULL
  AND p."year_2018"            IS NOT NULL
ORDER BY
    "percent_population_confirmed" DESC NULLS LAST;