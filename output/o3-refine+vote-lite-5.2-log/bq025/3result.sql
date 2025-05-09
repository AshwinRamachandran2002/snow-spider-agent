WITH under20 AS (
  SELECT
    country_code,
    ANY_VALUE(country_name) AS country_name,
    SUM(population) AS pop_under_20
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE
    year = 2020
    AND age < 20
  GROUP BY
    country_code
),
total_pop AS (
  SELECT
    country_code,
    country_name,
    midyear_population AS total_population
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE
    year = 2020
)
SELECT
  t.country_name,
  u.pop_under_20,
  t.total_population,
  ROUND(SAFE_DIVIDE(u.pop_under_20, t.total_population) * 100, 4) AS percent_under_20
FROM
  under20 u
JOIN
  total_pop t
USING (country_code)
WHERE
  t.total_population > 0
ORDER BY
  percent_under_20 DESC,
  t.country_name
LIMIT 10;