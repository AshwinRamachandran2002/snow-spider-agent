/* Percentage of each country's population that had been cumulatively
   confirmed with COVID-19 as of 2020-06-30                    */

SELECT
  c.iso_3166_1_alpha_3                                   AS iso3,
  c.country_name,
  c.cumulative_confirmed                                 AS confirmed_2020_06_30,
  p.year_2018                                            AS population_2018,
  ROUND(100 * c.cumulative_confirmed / p.year_2018, 6)   AS pct_pop_confirmed
FROM
  `bigquery-public-data.covid19_open_data.covid19_open_data`      AS c
JOIN
  `bigquery-public-data.world_bank_global_population.population_by_country` AS p
    ON p.country_code = c.iso_3166_1_alpha_3
WHERE
  c.date = '2020-06-30'      -- snapshot date
  AND c.aggregation_level = 0 -- country level only
  AND p.year_2018 IS NOT NULL -- keep records with population data
ORDER BY
  pct_pop_confirmed DESC;