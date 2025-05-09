SELECT
  p.country                                         AS country,
  p.year_2018                                       AS population_2018,
  c.cumulative_confirmed                            AS cases_2020_06_30,
  ROUND(100 * c.cumulative_confirmed / p.year_2018, 4) AS percent_of_population
FROM `bigquery-public-data.world_bank_global_population.population_by_country` AS p
JOIN `bigquery-public-data.covid19_open_data.covid19_open_data` AS c
  ON p.country_code = c.iso_3166_1_alpha_3
WHERE c.aggregation_level = 0                      -- country‑level data
  AND c.date = '2020-06-30'                        -- snapshot date
  AND p.year_2018 IS NOT NULL                      -- ensure population available
ORDER BY percent_of_population DESC, country;