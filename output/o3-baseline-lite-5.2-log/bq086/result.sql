-- Share of each country’s population that had been confirmed with COVID‑19
-- (cumulative cases up to 30 Jun 2020 ÷ 2018 population)

WITH covid_country AS (
  SELECT
    iso_3166_1_alpha_3                        AS country_code,      -- 3‑letter ISO
    ANY_VALUE(country_name)                   AS country_name,
    MAX(cumulative_confirmed)                 AS cumulative_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'
    AND aggregation_level = 0                 -- national totals only
    AND iso_3166_1_alpha_3 IS NOT NULL
  GROUP BY country_code
),

population_2018 AS (
  SELECT
    country_code,
    CAST(year_2018 AS INT64) AS population_2018
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2018 IS NOT NULL
)

SELECT
  c.country_name,
  c.country_code,
  c.cumulative_confirmed,
  p.population_2018,
  ROUND(SAFE_DIVIDE(c.cumulative_confirmed, p.population_2018) * 100, 4) AS percent_of_population_confirmed
FROM covid_country         AS c
JOIN population_2018       AS p
  ON c.country_code = p.country_code
WHERE p.population_2018 > 0
ORDER BY percent_of_population_confirmed DESC;