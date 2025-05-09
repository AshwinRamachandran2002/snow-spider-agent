WITH covid AS (
  -- Country–level cumulative confirmed cases on 30‑Jun‑2020
  SELECT
    iso_3166_1_alpha_3           AS country_code,      -- 3‑letter ISO code
    MAX(cumulative_confirmed)    AS cumulative_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'
    AND aggregation_level = 0            -- one row per country
    AND iso_3166_1_alpha_3 IS NOT NULL
  GROUP BY iso_3166_1_alpha_3
),
pop AS (
  -- 2018 population from World Bank
  SELECT
    country_code,                            -- 3‑letter ISO code
    country        AS country_name,
    CAST(year_2018 AS FLOAT64) AS population_2018
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2018 IS NOT NULL
)
SELECT
  pop.country_code,
  pop.country_name,
  covid.cumulative_confirmed,
  pop.population_2018,
  ROUND(covid.cumulative_confirmed / pop.population_2018 * 100, 4)
     AS confirmed_percent_of_population
FROM pop
JOIN covid USING (country_code)
ORDER BY confirmed_percent_of_population DESC;