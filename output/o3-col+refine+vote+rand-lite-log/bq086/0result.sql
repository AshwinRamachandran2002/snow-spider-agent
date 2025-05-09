-- Percentage of each country's population that had been confirmed
-- with COVID-19 by 30-Jun-2020
WITH covid_country AS (
  SELECT
    iso_3166_1_alpha_3            AS iso3,
    country_name,
    cumulative_confirmed
  FROM  `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE aggregation_level = 0              -- country-level rows only
    AND date              = '2020-06-30'   -- snapshot date
),
population_2018 AS (
  SELECT
    country_code            AS iso3,
    country                 AS pop_country_name,
    year_2018               AS population_2018
  FROM  `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2018 IS NOT NULL               -- keep countries with population data
)

SELECT
  c.country_name,
  c.iso3,
  c.cumulative_confirmed         AS confirmed_cases,
  p.population_2018,
  ROUND(100.0 * c.cumulative_confirmed / p.population_2018, 5)
                                AS percent_of_population_confirmed
FROM   covid_country     AS c
JOIN   population_2018   AS p  USING (iso3)
ORDER  BY percent_of_population_confirmed DESC, country_name;