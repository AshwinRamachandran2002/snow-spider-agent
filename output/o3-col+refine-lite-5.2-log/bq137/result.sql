-- Zip‑code polygons that lie within 10 km of (‑122.3321, 47.6062)   
-- together with land/water area, centroid coordinates, jurisdiction
-- strings, and 2010 all‑ages (male + female) population.
WITH pop AS (
  SELECT
    zipcode,
    SUM(population) AS total_population            -- all ages, male+female
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IN ('male','female')
    AND minimum_age IS NULL
    AND maximum_age IS NULL
  GROUP BY zipcode
)
SELECT
  ST_GEOGFROMTEXT(z.zipcode_geom) AS zipcode_polygon,
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  COALESCE(p.total_population, 0) AS total_population
FROM `bigquery-public-data.utility_us.zipcode_area` AS z
LEFT JOIN pop AS p
  ON z.zipcode = p.zipcode
WHERE ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),           -- convert WKT → GEOGRAPHY
        ST_GEOGPOINT(-122.3321, 47.6062),          -- target point (Seattle)
        10000                                      -- 10 000 m radius
      )
ORDER BY total_population DESC;