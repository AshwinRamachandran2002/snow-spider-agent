WITH under20 AS (
  -- Population aged 0‑19 in 2020 (sum of both sexes)
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(population) AS population_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020
    AND age < 20
  GROUP BY country_code
),
totalpop AS (
  -- Total mid‑year population in 2020
  SELECT
    country_code,
    ANY_VALUE(country_name)   AS country_name,
    ANY_VALUE(midyear_population) AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
  GROUP BY country_code
),
combined AS (
  SELECT
    u.country_code,
    u.country_name,
    u.population_under20,
    t.total_population,
    SAFE_DIVIDE(u.population_under20, t.total_population) * 100 AS pct_under20
  FROM under20 u
  JOIN totalpop t USING (country_code)
  WHERE t.total_population > 0
)
SELECT
  country_name,
  population_under20,
  total_population,
  ROUND(pct_under20, 4) AS pct_under20
FROM combined
ORDER BY pct_under20 DESC, country_name
LIMIT 10;