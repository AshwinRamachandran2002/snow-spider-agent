-- Top 3 countries with the highest 2017 net‑migration rates
-- among those whose land area exceeds 500 km²
SELECT
  m.`country_name`,
  m.`net_migration` AS migration_rate_per_1000_pop
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS m
JOIN `bigquery-public-data.census_bureau_international.country_names_area` AS a
  ON m.`country_code` = a.`country_code`
WHERE m.`year` = 2017
  AND a.`country_area` > 500
ORDER BY
  m.`net_migration` DESC,
  m.`country_name` ASC
LIMIT 3;