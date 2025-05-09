-- Zip code areas within 10 km (~6.2137 miles) of (-122.3321 , 47.6062)
-- together with their 2010 male + female total‑age population
WITH population_2010 AS (
  SELECT
    LPAD(zipcode, 5, '0')            AS zipcode,          -- make sure leading zeros are kept
    SUM(population)                  AS total_population  -- male + female, no age constraints
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IN ('male','female')
    AND minimum_age IS NULL          -- no age lower bound
    AND maximum_age IS NULL          -- no age upper bound
  GROUP BY zipcode
),
zip_areas AS (
  SELECT
    za.zipcode,
    ST_GEOGFROMTEXT(za.zipcode_geom) AS zipcode_geom,     -- polygon as GEOGRAPHY
    za.area_land_meters,
    za.area_water_meters,
    za.latitude,
    za.longitude,
    za.state_code,
    za.state_name,
    za.city,
    za.county
  FROM `bigquery-public-data.utility_us.zipcode_area` AS za
),
near_seattle AS (
  SELECT *
  FROM zip_areas
  WHERE ST_DWITHIN(
          zipcode_geom,                           -- ZIP polygon
          ST_GEOGPOINT(-122.3321, 47.6062),       -- Seattle lat/lon (lon, lat)
          10000                                   -- 10 000 meters  (10 km)
        )
)
SELECT
  ns.zipcode,
  ns.zipcode_geom,        -- polygon
  ns.area_land_meters,
  ns.area_water_meters,
  ns.latitude,
  ns.longitude,
  ns.state_code,
  ns.state_name,
  ns.city,
  ns.county,
  IFNULL(p.total_population, 0) AS total_population
FROM near_seattle AS ns
LEFT JOIN population_2010 AS p
USING (zipcode)
ORDER BY ns.zipcode;