-- Zip code areas within 10 km of (-122.3321 lon , 47.6062 lat) 
-- together with 2010 (male + female, all‑ages) population totals
WITH
center_point AS (
  SELECT ST_GEOGPOINT(-122.3321, 47.6062) AS geo
),

-- Zip‑code polygons that fall inside the 10 000‑meter buffer
nearby_zipcodes AS (
  SELECT
    z.zipcode,
    SAFE.ST_GEOGFROMTEXT(z.zipcode_geom)        AS zipcode_polygon,
    z.area_land_meters,
    z.area_water_meters,
    z.latitude,
    z.longitude,
    z.state_code,
    z.state_name,
    z.city,
    z.county
  FROM `bigquery-public-data.utility_us.zipcode_area` AS z
  CROSS JOIN center_point AS c
  WHERE z.zipcode_geom IS NOT NULL
    AND SAFE.ST_GEOGFROMTEXT(z.zipcode_geom) IS NOT NULL
    AND ST_DWITHIN(SAFE.ST_GEOGFROMTEXT(z.zipcode_geom), c.geo, 10000)  -- 10 km
),

-- 2010 population totals (male + female, no age constraints) by ZIP
population_2010 AS (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL          -- no age filter
    AND maximum_age IS NULL
    AND gender IN ('male', 'female') -- include only explicit male/female totals
  GROUP BY zipcode
)

SELECT
  nz.zipcode,
  nz.zipcode_polygon,
  nz.area_land_meters,
  nz.area_water_meters,
  nz.latitude,
  nz.longitude,
  nz.state_code,
  nz.state_name,
  nz.city,
  nz.county,
  IFNULL(p.total_population, 0) AS total_population
FROM nearby_zipcodes AS nz
LEFT JOIN population_2010 AS p
USING (zipcode)
ORDER BY total_population DESC, zipcode;