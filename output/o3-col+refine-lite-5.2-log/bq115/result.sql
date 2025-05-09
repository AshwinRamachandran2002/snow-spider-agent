WITH under25 AS (
  SELECT
    country_code,
    country_name,
    SUM(population) AS pop_under25
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2017
    AND age < 25
  GROUP BY country_code, country_name
),
total17 AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2017
)
SELECT
  u.country_name,
  100 * pop_under25 / total_pop AS pct_under25
FROM under25 u
JOIN total17 t
USING (country_code, country_name)
ORDER BY pct_under25 DESC
LIMIT 1;