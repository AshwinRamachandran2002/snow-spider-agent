SELECT
  z.zip_code AS Zip_code,
  ROUND(SUM(c.total_pop * (ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom)) / ST_AREA(t.tract_geom))), 4) AS Total_population,
  ROUND(
    SUM(c.income_per_capita * (ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom)) / ST_AREA(t.tract_geom)))
    / SUM(ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom)) / ST_AREA(t.tract_geom)), 4) AS Average_individual_income
FROM
  `bigquery-public-data.geo_census_tracts.us_census_tracts_national` AS t
JOIN
  `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` AS c
ON
  t.geo_id = c.geo_id
JOIN
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
ON
  ST_INTERSECTS(t.tract_geom, z.zip_code_geom)
WHERE
  z.state_code = 'WA' AND
  ST_DWITHIN(ST_GEOGPOINT(-122.191667, 47.685833), ST_CENTROID(z.zip_code_geom), 8046.72) -- 5 miles in meters
GROUP BY
  z.zip_code
ORDER BY
  Average_individual_income DESC;