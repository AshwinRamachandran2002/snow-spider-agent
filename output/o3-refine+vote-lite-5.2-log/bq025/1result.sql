WITH under20 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(population) AS population_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020
    AND age BETWEEN 0 AND 19
  GROUP BY country_code
),
totalpop AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(midyear_population) AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
  GROUP BY country_code
)
SELECT
  t.country_name,
  u.population_under20,
  t.total_population,
  ROUND(u.population_under20 * 100.0 / t.total_population, 4) AS percent_under20
FROM under20 u
JOIN totalpop t
  ON u.country_code = t.country_code
WHERE t.total_population > 0
ORDER BY percent_under20 DESC, t.country_name
LIMIT 10;