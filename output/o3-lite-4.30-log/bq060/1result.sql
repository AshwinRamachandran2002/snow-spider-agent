SELECT
  br.country_name AS country,
  ROUND(br.net_migration, 4) AS net_migration_rate_2017_per_1000_population
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS br
JOIN `bigquery-public-data.census_bureau_international.country_names_area`      AS ar
USING (country_code)
WHERE br.year = 2017
  AND ar.country_area > 500
ORDER BY br.net_migration DESC, br.country_name
LIMIT 3;