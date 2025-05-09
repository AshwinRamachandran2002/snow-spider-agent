SELECT
  bdgr.country_name,
  ROUND(bdgr.net_migration, 4) AS net_migration_rate_per_1000_population
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS bdgr
JOIN `bigquery-public-data.census_bureau_international.country_names_area` AS cna
USING (country_code)
WHERE bdgr.year = 2017
  AND cna.country_area > 500
ORDER BY bdgr.net_migration DESC, bdgr.country_name
LIMIT 3;