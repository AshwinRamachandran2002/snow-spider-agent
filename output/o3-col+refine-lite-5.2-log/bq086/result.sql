SELECT
  c.country_name                                       AS country,
  c.iso_3166_1_alpha_3                                 AS iso3,
  SUM(c.cumulative_confirmed)                          AS confirmed_as_of_2020_06_30,
  p.year_2018                                          AS population_2018,
  ROUND(100 * SUM(c.cumulative_confirmed) / p.year_2018, 4)
                                                      AS percent_of_population
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data` AS c
JOIN
  `bigquery-public-data.world_bank_global_population.population_by_country` AS p
ON
  p.country_code = c.iso_3166_1_alpha_3
WHERE
  c.date = '2020-06-30'
  AND c.aggregation_level = 0         -- country/territory level
  AND p.year_2018 IS NOT NULL         -- ensure population data exists
GROUP BY
  country,
  iso3,
  population_2018
ORDER BY
  percent_of_population DESC;