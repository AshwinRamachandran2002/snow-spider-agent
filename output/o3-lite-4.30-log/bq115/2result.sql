WITH under25 AS (
  SELECT
    country_code,
    country_name,
    SUM(population) AS pop_u25
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE
    year = 2017
    AND age < 25
  GROUP BY
    country_code,
    country_name
),
total_pop AS (
  SELECT
    country_code,
    midyear_population AS total_population
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE
    year = 2017
)
SELECT
  under25.country_name AS country,
  ROUND(100.0 * under25.pop_u25 / total_pop.total_population, 4) AS percentage_population_under_25_2017
FROM
  under25
JOIN
  total_pop
USING (country_code)
ORDER BY
  percentage_population_under_25_2017 DESC,
  country
LIMIT 1;