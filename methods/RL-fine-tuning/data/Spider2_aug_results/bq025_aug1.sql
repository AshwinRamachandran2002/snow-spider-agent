-- Task: Provide a list of the top 10 countries for the year 2020, ordered by the total population under 20 years old. For each country, include their names, total population under 20 years old, and total midyear population.
SELECT m.country_name AS Country_Name,
       a.total_under_20 AS Population_Under_20,
       m.midyear_population AS Total_Population
FROM `bigquery-public-data.census_bureau_international.midyear_population` AS m
JOIN (
  SELECT country_code, SUM(population) AS total_under_20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020 AND age < 20
  GROUP BY country_code
) AS a ON m.country_code = a.country_code
WHERE m.year = 2020
ORDER BY a.total_under_20 DESC
LIMIT 10;