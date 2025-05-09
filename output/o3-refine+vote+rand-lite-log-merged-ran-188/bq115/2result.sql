-- Country with the highest share of population younger than 25 in 2017
SELECT
  ANY_VALUE(country_name) AS country_name,
  SAFE_DIVIDE(SUM(CASE WHEN age < 25 THEN population ELSE 0 END),
              SUM(population)) * 100 AS percentage_under_25
FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
WHERE year = 2017
GROUP BY country_code
ORDER BY percentage_under_25 DESC
LIMIT 1;