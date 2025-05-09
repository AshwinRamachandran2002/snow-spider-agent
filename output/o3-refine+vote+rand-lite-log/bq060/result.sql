WITH area_filtered AS (
  SELECT
    country_code,
    country_name,
    country_area
  FROM
    `bigquery-public-data.census_bureau_international.country_names_area`
  WHERE
    country_area > 500
)
SELECT
  b.country_name,
  b.net_migration
FROM
  `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS b
JOIN
  area_filtered AS a
ON
  b.country_code = a.country_code
WHERE
  b.year = 2017
  AND b.net_migration IS NOT NULL
ORDER BY
  b.net_migration DESC,
  b.country_name
LIMIT 3;