SELECT
  c.iso_3166_1_alpha_3                                  AS country_code,
  c.country_name,
  c.cumulative_confirmed,
  p.year_2018                                           AS population_2018,
  ROUND(100 * c.cumulative_confirmed / p.year_2018, 4)  AS pct_of_population_confirmed
FROM  `bigquery-public-data.covid19_open_data.covid19_open_data`            AS c
JOIN  `bigquery-public-data.world_bank_global_population.population_by_country` AS p
      ON c.iso_3166_1_alpha_3 = p.country_code
WHERE c.date = '2020-06-30'
  AND c.aggregation_level = 0
  AND p.year_2018 IS NOT NULL
ORDER BY pct_of_population_confirmed DESC;