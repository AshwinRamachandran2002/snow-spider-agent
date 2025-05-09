WITH under20 AS (
  SELECT
    country_code,
    country_name,
    SUM(population) AS under20_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020
    AND age < 20
  GROUP BY country_code, country_name
)
SELECT
  u.country_name,
  u.under20_population,
  t.midyear_population AS total_population,
  ROUND(100 * SAFE_DIVIDE(u.under20_population, t.midyear_population), 2) AS pct_under20
FROM under20 AS u
JOIN `bigquery-public-data.census_bureau_international.midyear_population` AS t
  ON t.country_code = u.country_code
  AND t.year = 2020
ORDER BY pct_under20 DESC
LIMIT 10;