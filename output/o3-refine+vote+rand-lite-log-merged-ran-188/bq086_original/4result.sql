-- % of each country's population that had been cumulatively confirmed
-- with COVID‑19 as of 30 June 2020
WITH covid AS (
    SELECT
        iso_3166_1_alpha_3          AS country_code,      -- ISO‑3 code
        country_name,
        -- national level row for the requested date
        MAX(cumulative_confirmed)   AS cumulative_confirmed
    FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
    WHERE date = '2020-06-30'
      AND aggregation_level = 0              -- country level
      AND iso_3166_1_alpha_3 IS NOT NULL
    GROUP BY country_code, country_name
),
pop AS (
    SELECT
        country_code,
        year_2018 AS population_2018
    FROM `bigquery-public-data.world_bank_global_population.population_by_country`
    WHERE year_2018 IS NOT NULL
)
SELECT
    c.country_name,
    c.country_code,
    c.cumulative_confirmed,
    p.population_2018,
    ROUND(c.cumulative_confirmed / p.population_2018 * 100, 4) AS percent_population_confirmed
FROM covid c
JOIN pop  p
  ON c.country_code = p.country_code
ORDER BY percent_population_confirmed DESC;