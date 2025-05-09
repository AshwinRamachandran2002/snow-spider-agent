-- Country with the highest share of population younger than 25 in 2017
WITH under25 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(population) AS under25_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2017
    AND age < 25                -- ages 0‑24 inclusive
  GROUP BY country_code
),
totals AS (
  SELECT
    country_code,
    midyear_population AS total_pop
  FROM `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE year = 2017
)
SELECT
  u.country_name,
  ROUND(u.under25_pop / t.total_pop * 100, 2) AS percent_under_25
FROM under25 u
JOIN totals t
USING (country_code)
ORDER BY percent_under_25 DESC
LIMIT 1;