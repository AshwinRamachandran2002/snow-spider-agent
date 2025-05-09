WITH
-- cumulative confirmed cases by country on 2020‑06‑30
covid AS (
  SELECT
    iso_3166_1_alpha_3           AS country_code,   -- 3‑letter ISO code
    country_name,
    SAFE_CAST(cumulative_confirmed AS FLOAT64) AS cumulative_confirmed
  FROM `bigquery-public-data.covid19_open_data.covid19_open_data`
  WHERE date = '2020-06-30'
    AND aggregation_level = 0          -- national level
    AND cumulative_confirmed IS NOT NULL
),

-- 2018 population (latest year before 2020 available in the table)
pop AS (
  SELECT
    country_code,
    SAFE_CAST(year_2018 AS FLOAT64) AS population_2018
  FROM `bigquery-public-data.world_bank_global_population.population_by_country`
  WHERE year_2018 IS NOT NULL
)

SELECT
  c.country_name,
  c.country_code,
  c.cumulative_confirmed,
  p.population_2018 AS population_2018,
  ROUND( (c.cumulative_confirmed / p.population_2018) * 100 , 4) AS pct_of_population_confirmed
FROM covid c
JOIN pop  p
ON  c.country_code = p.country_code
ORDER BY pct_of_population_confirmed DESC, c.country_name;