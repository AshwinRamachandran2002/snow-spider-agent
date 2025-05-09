-- percentage of each country's population that had been confirmed with COVID‑19
-- (cumulative cases on 2020‑06‑30 ÷ 2018 population) * 100
SELECT
  pop.country            AS country_name,
  pop.country_code       AS iso3_code,
  pop.year_2018          AS population_2018,
  covid.cumulative_confirmed,
  SAFE_DIVIDE(covid.cumulative_confirmed , pop.year_2018) * 100 AS pct_population_confirmed
FROM
  `bigquery-public-data.world_bank_global_population.population_by_country`  AS pop
JOIN (
    SELECT
      iso_3166_1_alpha_3 AS iso3_code,
      MAX(cumulative_confirmed) AS cumulative_confirmed   -- one row per country/date=2020-06-30
    FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
    WHERE
      aggregation_level = 0             -- country level rows
      AND date = '2020-06-30'
    GROUP BY iso3_code
) AS covid
ON covid.iso3_code = pop.country_code
WHERE
  pop.year_2018 IS NOT NULL
ORDER BY
  pct_population_confirmed DESC, country_name;