-- Task: List the first 100 zip codes and block group IDs in Colorado where the zip codes and block groups overlap, along with the area of the overlap and the total area of the block group.

SELECT
  z.zip_code,
  b.geo_id,
  ST_AREA(ST_INTERSECTION(z.zip_code_geom, b.blockgroup_geom)) AS overlap_area,
  ST_AREA(b.blockgroup_geom) AS blockgroup_area
FROM
  `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
INNER JOIN
  `bigquery-public-data.geo_census_blockgroups.us_blockgroups_national` AS b
ON
  ST_INTERSECTS(z.zip_code_geom, b.blockgroup_geom)
WHERE
  z.state_code = 'CO'
  AND b.state_fips_code = '08'
LIMIT 100;