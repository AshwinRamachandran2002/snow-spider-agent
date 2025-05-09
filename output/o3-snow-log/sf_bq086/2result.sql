SELECT
    c19."country_name",
    c19."cumulative_confirmed",
    pop."year_2018"                                                   AS "population_2018",
    (c19."cumulative_confirmed" / pop."year_2018") * 100              AS "pct_population_confirmed"
FROM COVID19_OPEN_WORLD_BANK.COVID19_OPEN_DATA.COVID19_OPEN_DATA       AS c19
JOIN COVID19_OPEN_WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY AS pop
      ON c19."country_name" = pop."country"
WHERE c19."aggregation_level" = 0
  AND c19."date" = '2020-06-30'
ORDER BY "pct_population_confirmed" DESC NULLS LAST;