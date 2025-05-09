WITH under25 AS (
  SELECT
    country_code,
    SUM(population) AS pop_under25
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2017
    AND age < 25
  GROUP BY country_code
),
total AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2017
)
SELECT
  t.country_name,
  100.0 * u.pop_under25 / t.total_pop AS pct_under25
FROM total t
JOIN under25 u USING (country_code)
ORDER BY pct_under25 DESC
LIMIT 1;