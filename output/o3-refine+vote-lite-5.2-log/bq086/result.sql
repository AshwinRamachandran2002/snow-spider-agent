WITH covid_country AS (
  /*  Cumulative confirmed cases per country on 30‑Jun‑2020             */
  SELECT
    iso_3166_1_alpha_3          AS country_code,          -- ISO‑3 code
    MAX(country_name)           AS country_name,          -- name (for display)
    MAX(cumulative_confirmed)   AS cumulative_confirmed   -- total cases
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'            -- status as of 30‑Jun‑2020
    AND aggregation_level = 0          -- national level only
    AND cumulative_confirmed IS NOT NULL
  GROUP BY country_code
),
population_2018 AS (
  /*  2018 population from World Bank                                   */
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
  ROUND(100 * c.cumulative_confirmed / p.population_2018, 4) AS percent_of_population_confirmed
FROM covid_country      AS c
JOIN population_2018    AS p
  ON c.country_code = p.country_code
WHERE p.population_2018 > 0
ORDER BY percent_of_population_confirmed DESC, c.country_code;