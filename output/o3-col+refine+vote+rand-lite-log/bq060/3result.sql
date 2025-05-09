SELECT
  b.`country_name`,
  b.`net_migration` AS migration_rate_per_1000_pop
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS b
JOIN `bigquery-public-data.census_bureau_international.country_names_area` AS c
  ON b.`country_code` = c.`country_code`
WHERE
  b.`year` = 2017
  AND c.`country_area` > 500
ORDER BY
  b.`net_migration` DESC
LIMIT 3;