SELECT `country_name` AS Country_Name,
    ROUND((SUM(CASE WHEN `age` < 25 THEN `population` ELSE 0 END) / SUM(`population`)) * 100, 4) AS Percentage_Under_25
FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
WHERE `year` = 2017
GROUP BY `country_name`
ORDER BY Percentage_Under_25 DESC
LIMIT 1;