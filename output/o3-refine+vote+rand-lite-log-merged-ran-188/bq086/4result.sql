-- Percentage of each country's 2018 population that had been
-- cumulatively confirmed with COVID-19 by 2020-06-30
SELECT
  c.iso_3166_1_alpha_3                             AS country_code,
  c.country_name,
  p.year_2018                                      AS population_2018,
  c.cumulative_confirmed,
  ROUND(100 * SAFE_DIVIDE(c.cumulative_confirmed, p.year_2018), 4)
                                                  AS pct_population_confirmed
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`  AS c
JOIN `bigquery-public-data.world_bank_global_population.population_by_country` AS p
  ON c.iso_3166_1_alpha_3 = p.country_code
WHERE c.aggregation_level = 0          -- country–level rows only
  AND c.date = '2020-06-30'            -- snapshot date
  AND p.year_2018 IS NOT NULL          -- ensure population is available
ORDER BY pct_population_confirmed DESC;