SELECT
  bdgr.country_name,
  bdgr.net_migration
FROM
  `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS bdgr
JOIN
  `bigquery-public-data.census_bureau_international.country_names_area` AS cna
ON
  bdgr.country_code = cna.country_code
WHERE
  bdgr.year = 2017
  AND cna.country_area > 500
ORDER BY
  bdgr.net_migration DESC
LIMIT 3;