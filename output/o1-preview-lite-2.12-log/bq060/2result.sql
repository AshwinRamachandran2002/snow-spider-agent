SELECT
  b.country_name AS Country_Name,
  ROUND(b.net_migration, 4) AS Net_Migration_Rate
FROM
  `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS b
INNER JOIN
  `bigquery-public-data.census_bureau_international.country_names_area` AS c
ON
  b.country_code = c.country_code
WHERE
  b.year = 2017
  AND c.country_area > 500
ORDER BY
  b.net_migration DESC
LIMIT 3;