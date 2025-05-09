WITH under20 AS (
  SELECT
    country_code,
    country_name,
    SUM(population) AS pop_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020
    AND age BETWEEN 0 AND 19
  GROUP BY country_code, country_name
),
total_pop AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)
SELECT
  u.country_name,
  u.pop_under20 AS population_under_20,
  t.total_population,
  ROUND(u.pop_under20 / t.total_population * 100, 4) AS percent_under_20
FROM under20 u
JOIN total_pop t USING (country_code)
WHERE t.total_population > 0
ORDER BY percent_under_20 DESC, u.country_name
LIMIT 10;