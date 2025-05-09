SELECT
  z.zip_code,
  ROUND(SUM(t.total_pop), 1) AS population,
  ROUND(AVG(t.income_per_capita), 1) AS average_individual_income
FROM `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
JOIN `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS c
  ON ST_INTERSECTS(z.zip_code_geom, c.tract_geom)
JOIN `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` AS t
  ON c.geo_id = t.geo_id
WHERE z.state_code = 'WA'
  AND ST_DWithin(
    z.zip_code_geom,
    ST_GEOGPOINT(-122.191667, 47.685833),
    8046.72  -- 5 miles in meters
  )
GROUP BY z.zip_code
ORDER BY average_individual_income DESC;