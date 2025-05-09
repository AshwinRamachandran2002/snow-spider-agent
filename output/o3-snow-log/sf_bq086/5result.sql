SELECT
    c."country_name",
    c."iso_3166_1_alpha_3"                               AS "country_code",
    c."cumulative_confirmed",
    p."year_2018"                                        AS "population_2018",
    ROUND((c."cumulative_confirmed" / p."year_2018")*100, 4)
                                                        AS "pct_of_population_confirmed"
FROM  COVID19_OPEN_WORLD_BANK.COVID19_OPEN_DATA.COVID19_OPEN_DATA            c
JOIN  COVID19_OPEN_WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY p
      ON c."iso_3166_1_alpha_3" = p."country_code"
WHERE c."date" = '2020-06-30'
  AND c."aggregation_level" = 0
  AND p."year_2018" IS NOT NULL
ORDER BY "pct_of_population_confirmed" DESC NULLS LAST;