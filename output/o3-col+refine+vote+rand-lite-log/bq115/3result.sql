-- Country with the highest share of population younger than 25 in 2017
WITH under25 AS (
  SELECT
    country_code,
    SUM(midyear_population) AS pop_under_25
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = 'A'            -- individual 5-year age-groups
    AND age_group_indicator = '-'   -- closed 5-year intervals
    AND starting_age < 25           -- ages 0-24
  GROUP BY country_code
),
tot AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = '*'            -- total, all ages
    AND starting_age = 0
    AND age_group_indicator = '+'
)
SELECT
  t.country_name,
  ROUND(100 * u.pop_under_25 / t.total_pop, 2) AS pct_under_25
FROM under25 u
JOIN tot t USING (country_code)
ORDER BY pct_under_25 DESC
LIMIT 1;