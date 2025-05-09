SELECT
  z.zip_code,
  c.total_pop AS population,
  c.income_per_capita AS average_individual_income
FROM `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
JOIN `bigquery-public-data.census_bureau_acs.zcta5_2017_5yr` AS c
  ON z.zip_code = SUBSTR(c.geo_id, -5)
WHERE z.state_code = 'WA'
  AND ST_DWithin(
    z.zip_code_geom,
    ST_GEOGPOINT(-122.191667, 47.685833),
    8046.72  -- 5 miles in meters
  )
ORDER BY average_individual_income DESC;