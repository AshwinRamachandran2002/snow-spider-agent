SELECT
  covid.country_name,
  (MAX(covid.cumulative_confirmed) / pop.year_2018) * 100 AS confirmed_cases_percentage
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data` AS covid
JOIN
  `bigquery-public-data.world_bank_global_population.population_by_country` AS pop
ON
  covid.iso_3166_1_alpha_3 = pop.country_code
WHERE
  covid.date <= '2020-06-30'
  AND covid.aggregation_level = 1
  AND covid.cumulative_confirmed IS NOT NULL
  AND pop.year_2018 IS NOT NULL
GROUP BY
  covid.country_name, pop.year_2018