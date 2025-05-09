-- Percentage of each country's population confirmed with COVID-19
-- (cumulative cases up to 30-Jun-2020 divided by 2018 population)

WITH covid AS (
  SELECT
    iso_3166_1_alpha_3          AS country_code,
    country_name,
    cumulative_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE aggregation_level = 0          -- national totals
    AND date = '2020-06-30'            -- snapshot date
),
pop AS (
  SELECT
    country_code,
    year_2018 AS population_2018
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2018 IS NOT NULL          -- keep countries with population data
)

SELECT
  c.country_code,
  c.country_name,
  c.cumulative_confirmed,
  p.population_2018,
  ROUND(SAFE_DIVIDE(c.cumulative_confirmed, p.population_2018) * 100, 4)
      AS percent_population_confirmed
FROM covid AS c
JOIN pop   AS p USING (country_code)
ORDER BY percent_population_confirmed DESC;