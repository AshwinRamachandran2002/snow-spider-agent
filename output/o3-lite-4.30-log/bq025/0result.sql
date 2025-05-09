WITH under20 AS (
  SELECT
    country_code,
    country_name,
    SUM(population) AS total_population_under_20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020
    AND age < 20
  GROUP BY country_code, country_name
),
total AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_midyear_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)
SELECT
  t.country_name AS country,
  u.total_population_under_20,
  t.total_midyear_population,
  ROUND(100 * u.total_population_under_20 / t.total_midyear_population, 4) AS percent_under_20
FROM total t
JOIN under20 u USING (country_code)
ORDER BY percent_under_20 DESC, country
LIMIT 10;