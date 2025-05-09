SELECT
  bd.`country_name`,
  bd.`net_migration` AS migration_rate_per_1000
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS bd
JOIN `bigquery-public-data.census_bureau_international.country_names_area` AS ca
  ON bd.`country_code` = ca.`country_code`
WHERE
  bd.`year` = 2017
  AND ca.`country_area` > 500
ORDER BY
  bd.`net_migration` DESC
LIMIT 3;