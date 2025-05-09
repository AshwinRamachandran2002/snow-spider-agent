-- Percentage of every country's 2018 population that had been confirmed
-- with COVID-19 by 30 June 2020
WITH covid AS (
  SELECT
    iso_3166_1_alpha_3        AS iso3,
    SUM(cumulative_confirmed) AS cum_confirmed_2020_06_30
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'
    AND aggregation_level = 0          -- national totals only
  GROUP BY iso3
),
pop AS (
  SELECT
    country_code AS iso3,
    country      AS country_name,
    year_2018    AS population_2018
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2018 IS NOT NULL
)
SELECT
  p.iso3                              AS country_code_iso3,
  p.country_name,
  c.cum_confirmed_2020_06_30          AS cumulative_confirmed,
  p.population_2018,
  ROUND( SAFE_DIVIDE(c.cum_confirmed_2020_06_30, p.population_2018) * 100 ,4)
        AS percent_of_population_confirmed
FROM covid c
JOIN pop   p ON p.iso3 = c.iso3
ORDER BY percent_of_population_confirmed DESC;