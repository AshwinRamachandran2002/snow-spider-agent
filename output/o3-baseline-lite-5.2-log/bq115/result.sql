WITH under25 AS (
  SELECT
    country_code,
    SUM(population) AS pop_under_25
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE
    year = 2017
    AND age <= 24
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
    year = 2017
)
SELECT
  t.country_name,
  (u.pop_under_25 / t.total_population) * 100 AS percentage_under_25
FROM
  under25 u
JOIN
  total_pop t
USING (country_code)
ORDER BY
  percentage_under_25 DESC,
  country_name
LIMIT 1;