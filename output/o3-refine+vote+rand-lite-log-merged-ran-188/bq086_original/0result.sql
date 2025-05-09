WITH covid AS (
  -- Country‑level cumulative confirmed cases on 30 Jun 2020
  SELECT
    country_name,
    iso_3166_1_alpha_3 AS country_code,
    cumulative_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'
    AND aggregation_level = 0
),
pop AS (
  -- 2018 population from World Bank
  SELECT
    country AS country_name,
    country_code,
    year_2018 AS population_2018
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
)
SELECT
  c.country_name,
  c.country_code,
  c.cumulative_confirmed,
  p.population_2018,
  ROUND(SAFE_DIVIDE(c.cumulative_confirmed, p.population_2018) * 100, 4) AS pct_population_confirmed
FROM covid AS c
JOIN pop  AS p
  ON c.country_code = p.country_code
WHERE p.population_2018 IS NOT NULL
ORDER BY pct_population_confirmed DESC;