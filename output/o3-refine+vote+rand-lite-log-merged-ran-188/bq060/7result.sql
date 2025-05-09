SELECT
  br.country_name,
  br.net_migration
FROM
  `bigquery-public-data.census_bureau_international.birth_death_growth_rates` AS br
JOIN
  `bigquery-public-data.census_bureau_international.country_names_area`     AS ca
USING (country_code)
WHERE
  br.year = 2017
  AND ca.country_area > 500               -- area greater than 500 km²
  AND br.net_migration IS NOT NULL        -- exclude missing values
ORDER BY
  br.net_migration DESC,                  -- highest net migration first
  br.country_name                         -- tie‑breaker
LIMIT 3;