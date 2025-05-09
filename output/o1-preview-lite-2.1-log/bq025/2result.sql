SELECT mp.`country_name`, under20.`population_under_20`, mp.`midyear_population`,
       ROUND((under20.`population_under_20` / mp.`midyear_population`) * 100, 4) AS `percentage_under_20`
FROM `bigquery-public-data.census_bureau_international.midyear_population` AS mp
JOIN (
  SELECT `country_code`, SUM(`population`) AS `population_under_20`
  FROM `bigquery-public-data.census_bureau_international.midyear_population_agespecific`
  WHERE `year` = 2020 AND `age` < 20
  GROUP BY `country_code`
) AS under20
ON mp.`country_code` = under20.`country_code`
WHERE mp.`year` = 2020
ORDER BY `percentage_under_20` DESC
LIMIT 10;