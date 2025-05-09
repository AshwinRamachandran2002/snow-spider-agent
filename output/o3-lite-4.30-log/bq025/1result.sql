WITH under20 AS (
  SELECT
    country_code,
    SUM(midyear_population) AS total_population_under_20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2020
    AND total_flag = 'A'          -- individual 5‑year age groups
    AND age_group_indicator = '-' -- closed 5‑year bands (e.g., 0‑4, 5‑9 …)
    AND starting_age < 20         -- ages 0‑19
  GROUP BY country_code
),
totals AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_midyear_population
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2020
)
SELECT
  t.country_name AS country,
  u.total_population_under_20,
  t.total_midyear_population,
  ROUND(100 * u.total_population_under_20 / t.total_midyear_population, 4) AS percent_under_20
FROM under20 u
JOIN totals t USING (country_code)
ORDER BY percent_under_20 DESC, country
LIMIT 10;