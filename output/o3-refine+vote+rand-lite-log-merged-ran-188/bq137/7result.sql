-- ZIP‑code areas within 10 km (~6.2 mi) of Seattle downtown  
--  • include each ZIP polygon and attributes from utility_us.zipcode_area  
--  • attach 2010 Census population (male + female, no age limits)  

WITH population_2010 AS (      -- 1)  total male+female pop per ZIP
  SELECT
    LPAD(zipcode, 5, '0') AS zipcode,
    SUM(population)       AS total_population
  FROM  `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IN ('male','female')
    AND minimum_age IS NULL
    AND maximum_age IS NULL
  GROUP BY zipcode
),

nearby_zips AS (               -- 2)  ZIP polygons within 10 000 m of (-122.3321, 47.6062)
  SELECT
    z.zipcode,
    ST_GEOGFROMTEXT(z.zipcode_geom)      AS zip_geom,          -- polygon / multipolygon
    z.area_land_meters,
    z.area_water_meters,
    z.latitude,
    z.longitude,
    z.state_code,
    z.state_name,
    z.city,
    z.county
  FROM  `bigquery-public-data.utility_us.zipcode_area` AS z
  WHERE z.zipcode_geom IS NOT NULL
    AND ST_DWITHIN(
          ST_GEOGFROMTEXT(z.zipcode_geom),
          ST_GEOGPOINT(-122.3321, 47.6062),      -- (lon, lat)
          10000                                   -- meters
        )
)

SELECT
  n.zipcode,
  n.zip_geom                        AS zipcode_polygon,        -- GEOGRAPHY
  n.area_land_meters,
  n.area_water_meters,
  n.latitude,
  n.longitude,
  n.state_code,
  n.state_name,
  n.city,
  n.county,
  COALESCE(p.total_population, 0)   AS total_population_2010
FROM      nearby_zips        AS n
LEFT JOIN population_2010    AS p
USING     (zipcode)
ORDER BY  n.zipcode;