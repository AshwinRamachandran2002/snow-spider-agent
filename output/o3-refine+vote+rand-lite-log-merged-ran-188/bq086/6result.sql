/*  Percentage of each country's population that had been
    cumulatively confirmed with COVID-19 by 30 Jun 2020          */

SELECT
  c.country_name,
  c.iso_3166_1_alpha_3               AS iso3,
  c.cumulative_confirmed             AS cumulative_confirmed_2020_06_30,
  p.year_2018                        AS population_2018,
  ROUND(100.0 * c.cumulative_confirmed / p.year_2018, 4)
                                    AS percent_population_confirmed
FROM `bigquery-public-data.covid19_open_data.covid19_open_data`   AS c
JOIN `bigquery-public-data.world_bank_global_population.population_by_country` AS p
  ON c.iso_3166_1_alpha_3 = p.country_code
WHERE c.date = '2020-06-30'      -- snapshot date
  AND c.aggregation_level = 0    -- one row per country
  AND p.year_2018 IS NOT NULL;   -- keep countries with population data