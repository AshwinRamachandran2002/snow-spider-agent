SELECT
  c.country_name,
  ROUND((c.cumulative_confirmed / NULLIF(p.year_2018, 0)) * 100, 4) AS confirmed_cases_percentage
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data` AS c
JOIN
  `bigquery-public-data.world_bank_global_population.population_by_country` AS p
ON
  c.iso_3166_1_alpha_3 = p.country_code
WHERE
  c.date = '2020-06-30'
  AND c.aggregation_level = 0
ORDER BY
  confirmed_cases_percentage DESC