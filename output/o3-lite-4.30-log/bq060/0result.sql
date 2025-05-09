SELECT
  b.`country_name` AS country,
  FORMAT('%.4f', b.`net_migration`) AS net_migration_rate_2017_per_1000_population
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS b
JOIN `bigquery-public-data.census_bureau_international.country_names_area` AS a
  ON b.`country_code` = a.`country_code`
WHERE b.`year` = 2017
  AND a.`country_area` > 500
ORDER BY b.`net_migration` DESC
LIMIT 3;