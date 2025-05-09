SELECT mp.`country_name` AS Country_Name,
       SUM(mpa.`population`) AS Population_Under_20,
       mp.`midyear_population` AS Total_Population,
       ROUND((SUM(mpa.`population`) / mp.`midyear_population`)*100, 4) AS Percentage_Under_20
FROM `bigquery-public-data.census_bureau_international.midyear_population` AS mp
JOIN `bigquery-public-data.census_bureau_international.midyear_population_agespecific` AS mpa
  ON mp.`country_code` = mpa.`country_code`
  AND mp.`year` = mpa.`year`
WHERE mp.`year` = 2020
  AND mpa.`age` < 20
GROUP BY mp.`country_code`, mp.`country_name`, mp.`midyear_population`
ORDER BY Percentage_Under_20 DESC
LIMIT 10;