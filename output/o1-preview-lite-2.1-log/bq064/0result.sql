SELECT
  z.zip_code,
  ROUND(c.total_pop, 1) AS population,
  ROUND(c.income_per_capita, 1) AS average_individual_income
FROM
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
JOIN
  `bigquery-public-data.census_bureau_acs.zip_codes_2017_5yr` AS c
ON
  z.zip_code = c.geo_id
WHERE
  z.state_name = 'Washington'
  AND z.zip_code_geom IS NOT NULL
  AND ST_DWithin(
    z.zip_code_geom,
    ST_GeogPoint(-122.191667, 47.685833),
    8046.72  -- 5 miles in meters
  )
ORDER BY
  average_individual_income DESC;