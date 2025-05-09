WITH total_pop AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_population_2017
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = '*'
    AND starting_age = 0                 -- 0+ open-ended group = total
),
under25 AS (
  SELECT
    country_code,
    SUM(midyear_population) AS population_under25_2017
  FROM `bigquery-public-data.census_bureau_international.midyear_population_5yr_age_sex`
  WHERE year = 2017
    AND total_flag = 'A'                 -- individual 5-year age groups
    AND starting_age IN (0, 5, 10, 15, 20)
  GROUP BY country_code
)
SELECT
  t.country_name            AS highest_under25_country,
  100.0 * u.population_under25_2017 / t.total_population_2017 AS percent_under25
FROM total_pop t
JOIN under25 u
USING (country_code)
ORDER BY percent_under25 DESC
LIMIT 1;