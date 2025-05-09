SELECT
  r.`country_name`,
  r.`net_migration` AS migration_rate_per_1000_population
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS r
JOIN `bigquery-public-data.census_bureau_international.country_names_area` AS a
  ON r.`country_code` = a.`country_code`
WHERE r.`year` = 2017
  AND a.`country_area` > 500
ORDER BY r.`net_migration` DESC
LIMIT 3;