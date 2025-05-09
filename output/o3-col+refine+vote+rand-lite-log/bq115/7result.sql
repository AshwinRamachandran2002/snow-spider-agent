WITH under25 AS (
  SELECT
    country_code,
    SUM(midyear_population) AS pop_under_25
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND age_group_indicator = '-'          -- regular 5-year groups
    AND starting_age <= 24                 -- 0-4 … 20-24  ⇒ under-25
  GROUP BY country_code
),
total_pop AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = '*'                   -- total, all ages
    AND age_group_indicator = '+'          -- open-ended (whole population)
)
SELECT
  u.country_code,
  t.country_name,
  ROUND(u.pop_under_25 / t.total_population * 100, 2) AS pct_under_25
FROM under25 u
JOIN total_pop t USING (country_code)
ORDER BY pct_under_25 DESC
LIMIT 1;