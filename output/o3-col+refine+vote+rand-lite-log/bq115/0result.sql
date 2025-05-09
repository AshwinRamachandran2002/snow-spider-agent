-- Which country had the highest share of people under 25 in 2017?
WITH under25 AS (
  SELECT
    country_code,
    country_name,
    SUM(midyear_population) AS pop_under25
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = 'A'        -- five-year age groups
    AND starting_age < 25
  GROUP BY country_code, country_name
),
totals AS (
  SELECT
    country_code,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = '*'        -- total, all ages
)
SELECT
  u.country_name,
  100 * u.pop_under25 / t.total_pop AS pct_under25
FROM under25 u
JOIN totals t USING (country_code)
ORDER BY pct_under25 DESC
LIMIT 1;