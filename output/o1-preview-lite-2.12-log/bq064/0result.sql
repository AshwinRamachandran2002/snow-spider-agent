WITH buffer AS (
  SELECT ST_BUFFER(ST_GEOGPOINT(-122.191667, 47.685833), 8046.72) AS geom
),
tracts AS (
  SELECT 
    t.geo_id,
    t.tract_geom,
    c.total_pop,
    c.income_per_capita
  FROM 
    `bigquery-public-data.geo_census_tracts.us_census_tracts_national` t
  JOIN 
    `bigquery-public-data.census_bureau_acs.censustract_2017_5yr` c
  ON 
    t.geo_id = c.geo_id
  WHERE 
    t.state_name = 'Washington'
    AND ST_INTERSECTS(t.tract_geom, (SELECT geom FROM buffer))
),
zip_codes AS (
  SELECT 
    z.zip_code,
    z.zip_code_geom
  FROM 
    `bigquery-public-data.geo_us_boundaries.zip_codes` z
  WHERE 
    z.state_name = 'Washington'
    AND ST_DWithin(z.zip_code_geom, ST_GEOGPOINT(-122.191667, 47.685833), 8046.72)
),
tract_zip_overlap AS (
  SELECT 
    z.zip_code, 
    t.geo_id,
    t.total_pop,
    t.income_per_capita,
    ST_AREA(t.tract_geom) AS tract_area,
    ST_AREA(ST_INTERSECTION(t.tract_geom, z.zip_code_geom)) AS intersection_area
  FROM tracts t
  JOIN zip_codes z
  ON ST_INTERSECTS(t.tract_geom, z.zip_code_geom)
),
allocated AS (
  SELECT
    zip_code,
    SAFE_DIVIDE(intersection_area, tract_area) AS proportion,
    total_pop * SAFE_DIVIDE(intersection_area, tract_area) AS allocated_pop,
    (total_pop * income_per_capita) * SAFE_DIVIDE(intersection_area, tract_area) AS allocated_income
  FROM tract_zip_overlap
  WHERE tract_area > 0 AND intersection_area > 0
),
zip_code_totals AS (
  SELECT
    zip_code,
    SUM(allocated_pop) AS total_population,
    SUM(allocated_income) AS total_income
  FROM allocated
  GROUP BY zip_code
),
final_result AS (
  SELECT
    zip_code,
    ROUND(total_population, 1) AS Total_population,
    ROUND(SAFE_DIVIDE(total_income, NULLIF(total_population, 0)), 1) AS Average_individual_income
  FROM zip_code_totals
  WHERE total_population > 0
)
SELECT * FROM final_result
ORDER BY Average_individual_income DESC;