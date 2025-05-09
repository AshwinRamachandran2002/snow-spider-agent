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