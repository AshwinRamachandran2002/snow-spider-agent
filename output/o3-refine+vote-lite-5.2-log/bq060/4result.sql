SELECT
  br.country_name,
  br.net_migration
FROM
  `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS br
JOIN
  `bigquery-public-data.census_bureau_international.country_names_area` AS ca
ON
  br.country_code = ca.country_code
WHERE
  br.year = 2017
  AND ca.country_area > 500
ORDER BY
  br.net_migration DESC,
  br.country_name
LIMIT 3;