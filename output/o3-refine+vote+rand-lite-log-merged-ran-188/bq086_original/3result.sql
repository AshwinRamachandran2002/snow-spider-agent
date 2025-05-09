WITH covid_country AS (
  -- Cumulative confirmed cases per country on 2020‑06‑30 (national level only)
  SELECT
    iso_3166_1_alpha_3            AS country_code,
    country_name,
    MAX(cumulative_confirmed)     AS cumulative_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'          -- 30 June 2020
    AND aggregation_level = 0        -- country‑level records
  GROUP BY country_code, country_name
),
pop_2018 AS (
  -- 2018 population from World Bank
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
FROM covid_country c
JOIN pop_2018     p USING (country_code)
WHERE p.population_2018 > 0
ORDER BY percent_population_confirmed DESC;