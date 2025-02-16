-- Task: List the top 100 countries by percentage of population under the age of 25 in 2017.
SELECT
  age.country_name,
  ROUND((SUM(age.population) / pop.midyear_population) * 100, 2) AS pct_under_25
FROM (
  SELECT
    country_name,
    population,
    country_code
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE
    year = 2017
    AND age < 25
) age
INNER JOIN (
  SELECT
    midyear_population,
    country_code
  FROM
    `bigquery-public-data.census_bureau_international.midyear_population`
  WHERE
    year = 2017
) pop
ON
  age.country_code = pop.country_code
GROUP BY
  age.country_name,
  pop.midyear_population
ORDER BY
  pct_under_25 DESC
LIMIT
  100