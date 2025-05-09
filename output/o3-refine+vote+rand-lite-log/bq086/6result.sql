-- Percentage of each country's population confirmed with COVID‑19
-- (cumulative cases up to 30 Jun 2020 / 2018 population)
WITH covid AS (
  SELECT
    iso_3166_1_alpha_3             AS country_code,
    country_name,
    MAX(cumulative_confirmed)      AS cumulative_confirmed          -- one row per country/date, MAX is safe
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'
    AND aggregation_level = 0      -- country‑level records only
  GROUP BY country_code, country_name
)

SELECT
  covid.country_code,
  covid.country_name,
  covid.cumulative_confirmed,
  pop.year_2018                    AS population_2018,
  ROUND(covid.cumulative_confirmed * 100.0 / pop.year_2018, 4)
                                    AS pct_population_confirmed
FROM covid
JOIN `bigquery-public-data.world_bank_global_population.population_by_country` AS pop
  ON covid.country_code = pop.country_code
WHERE pop.year_2018 IS NOT NULL
ORDER BY pct_population_confirmed DESC;