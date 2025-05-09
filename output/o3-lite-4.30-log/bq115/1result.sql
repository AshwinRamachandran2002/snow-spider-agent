WITH under25 AS (
  SELECT
    country_code,
    country_name,
    SUM(midyear_population) AS under25_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = 'A'
    AND starting_age < 25
  GROUP BY country_code, country_name
),
allages AS (
  SELECT
    country_code,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = '*'
    AND starting_age = 0
    AND age_group_indicator = '+'
)
SELECT
  u.country_name AS country,
  ROUND(100 * u.under25_pop / a.total_pop, 4) AS percentage_population_under_25_2017
FROM under25 u
JOIN allages a USING (country_code)
ORDER BY percentage_population_under_25_2017 DESC, country
LIMIT 1;