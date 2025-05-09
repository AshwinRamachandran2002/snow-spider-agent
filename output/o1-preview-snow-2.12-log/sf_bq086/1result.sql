SELECT
  p."country" AS "Country_Name",
  ROUND((MAX(c."cumulative_confirmed") / p."year_2018") * 100, 4) AS "Percentage_Infected"
FROM
  COVID19_OPEN_WORLD_BANK.COVID19_OPEN_DATA.COVID19_OPEN_DATA c
JOIN
  COVID19_OPEN_WORLD_BANK.WORLD_BANK_GLOBAL_POPULATION.POPULATION_BY_COUNTRY p
  ON c."iso_3166_1_alpha_3" = p."country_code"
WHERE
  c."date" = '2020-06-30'
  AND c."aggregation_level" = 1
  AND c."cumulative_confirmed" IS NOT NULL
  AND p."year_2018" IS NOT NULL
GROUP BY
  p."country", p."year_2018"
ORDER BY
  "Percentage_Infected" DESC NULLS LAST;