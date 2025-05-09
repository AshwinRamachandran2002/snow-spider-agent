-- Country with the highest share of population younger than 25 years in 2017
WITH under25 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(population) AS pop_under25
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2017
    AND age < 25
  GROUP BY country_code
),
total_pop AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2017
)
SELECT
  t.country_name,
  (u.pop_under25 / t.total_population) * 100 AS percent_under25
FROM under25 u
JOIN total_pop t USING (country_code)
ORDER BY percent_under25 DESC
LIMIT 1;