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
    ANY_VALUE(country_name) AS country_name,
    SUM(midyear_population) AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
  GROUP BY country_code
)
SELECT
  t.country_name,
  p.pop_under20,
  t.total_pop,
  ROUND(100 * p.pop_under20 / t.total_pop, 4) AS pct_under20
FROM pop_under20 p
JOIN total_pop t USING (country_code)
WHERE t.total_pop > 0
ORDER BY pct_under20 DESC, t.country_name
LIMIT 10;