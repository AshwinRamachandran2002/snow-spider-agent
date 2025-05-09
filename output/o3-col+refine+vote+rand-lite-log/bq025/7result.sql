WITH pop_under20 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(population) AS pop_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020
    AND age BETWEEN 0 AND 19
  GROUP BY country_code
),
total_pop AS (
  SELECT
    country_code,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)
SELECT
  p.country_name,
  p.pop_under20        AS population_under20,
  t.total_pop          AS total_population,
  ROUND(p.pop_under20 / t.total_pop * 100, 4) AS percent_under20
FROM pop_under20 p
JOIN total_pop t
  ON p.country_code = t.country_code
ORDER BY percent_under20 DESC
LIMIT 10;