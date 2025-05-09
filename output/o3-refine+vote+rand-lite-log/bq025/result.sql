-- Top 10 countries in 2020 with the highest share of population under 20 years old
WITH under20 AS (
  -- Sum the population of all 5‑year age‑groups whose starting age is below 20
  SELECT
    country_code,
    SUM(midyear_population) AS population_under20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2020
    AND total_flag = 'A'          -- individual 5‑year age groups
    AND age_group_indicator = '-' -- closed 5‑year groups (e.g., 0‑4, 5‑9 …)
    AND starting_age < 20         -- ages 0‑19
  GROUP BY country_code
),
totals AS (
  -- Total mid‑year population (all ages, both sexes)
  SELECT
    country_code,
    country_name,
    midyear_population AS total_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)
SELECT
  t.country_name,
  u.population_under20,
  t.total_population,
  ROUND(100 * u.population_under20 / t.total_population, 4) AS percentage_under20
FROM totals t
JOIN under20 u
  ON t.country_code = u.country_code
ORDER BY percentage_under20 DESC, t.country_name
LIMIT 10;