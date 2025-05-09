SELECT
  b.`country_name`      AS country,
  b.`net_migration`     AS migration_rate_per_1000
FROM `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS b
JOIN `bigquery-public-data.census_bureau_international.country_names_area`      AS a
ON   b.`country_code` = a.`country_code`
WHERE b.`year` = 2017
  AND a.`country_area` > 500            -- keep only countries larger than 500 km²
ORDER BY b.`net_migration` DESC         -- highest migration rates first
LIMIT 3;                                -- top-3 countries