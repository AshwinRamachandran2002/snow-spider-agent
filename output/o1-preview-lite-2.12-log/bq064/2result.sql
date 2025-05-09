WITH tract_data AS (
  SELECT
    c.geo_id,
    c.total_pop,
    c.income_per_capita,
    g.tract_geom
  FROM
    `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` AS c
  JOIN
    `bigquery-public-data.geo_census_tracts.census_tracts_washington` AS g
  ON
    c.geo_id = g.geo_id
),
zip_codes_within_radius AS (
  SELECT
    z.zip_code,
    z.zip_code_geom
  FROM
    `bigquery-public-data.geo_us_boundaries.zip_codes` AS z
  WHERE
    z.state_code = 'WA'
    AND ST_DWithin(
      z.zip_code_geom,
      ST_GEOGPOINT(-122.191667, 47.685833),
      8046.72  -- 5 miles in meters
    )
),
intersections AS (
  SELECT
    t.geo_id,
    t.total_pop,
    t.income_per_capita,
    z.zip_code,
    ST_Area(ST_Intersection(t.tract_geom, z.zip_code_geom)) AS intersection_area,
    ST_Area(t.tract_geom) AS tract_area
  FROM
    tract_data AS t
  JOIN
    zip_codes_within_radius AS z
  ON
    ST_Intersects(t.tract_geom, z.zip_code_geom)
),
allocations AS (
  SELECT
    zip_code,
    (total_pop * (intersection_area / tract_area)) AS allocated_population,
    (total_pop * income_per_capita * (intersection_area / tract_area)) AS allocated_income
  FROM
    intersections
  WHERE
    intersection_area > 0
)
SELECT
  zip_code,
  ROUND(SUM(allocated_population), 1) AS total_population,
  ROUND(SUM(allocated_income) / SUM(allocated_population), 1) AS average_individual_income
FROM
  allocations
GROUP BY
  zip_code
ORDER BY
  average_individual_income DESC;