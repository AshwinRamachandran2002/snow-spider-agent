-- Task: Which country had the highest percentage of its total midyear population under the age of 25 in 2017?
SELECT
country_name
FROM
(SELECT
  age.country_name,
  SUM(age.population) AS under_25,
  pop.midyear_population AS total,
  ROUND((SUM(age.population) / pop.midyear_population) * 100,2) AS pct_under_25
FROM (
  SELECT
    country_name,
    population,
    country_code
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE
    year =2017
    AND age < 25) age
INNER JOIN (
  SELECT
    midyear_population,
    country_code
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE
    year = 2017) pop
ON
  age.country_code = pop.country_code
GROUP BY
  1,
  3
ORDER BY
  4 DESC
)
LIMIT
1