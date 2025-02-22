-- Task: Provide a list of the top 10 countries for the year 2020, ordered by the highest percentage of their population under the age of 20 (ages 0 to 19). For each country, include the total population under 20 years old (summed across all ages less than 20), the total midyear population, and the percentage of the population that is under 20 years old (calculated as (population under 20 / total midyear population) * 100, rounded to four decimal places).

SELECT m.country_name AS Country_Name,
       a.total_under_20 AS Population_Under_20,
       m.midyear_population AS Total_Population,
       ROUND((a.total_under_20 / m.midyear_population) * 100, 4) AS Percentage_Under_20
FROM `bigquery-public-data.census_bureau_international.midyear_population` AS m
JOIN (
  SELECT country_code, SUM(population) AS total_under_20
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE year = 2020 AND age < 20
  GROUP BY country_code
) AS a ON m.country_code = a.country_code
WHERE m.year = 2020
ORDER BY Percentage_Under_20 DESC
LIMIT 10;