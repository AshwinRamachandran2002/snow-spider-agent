-- Zip code areas within 10 km of (-122.3321 lon , 47.6062 lat)  
-- together with 2010 Census population (male + female, all ages)
SELECT
  z.zipcode,
  -- polygon of the ZIP Code Tabulation Area
  ST_GEOGFROMTEXT(z.zipcode_geom)       AS zipcode_polygon,
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  p.total_population
FROM `bigquery-public-data.utility_us.zipcode_area`            AS z
JOIN (
    SELECT
      zipcode,
      SUM(population) AS total_population
    FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
    WHERE
          minimum_age IS NULL           -- no age constraint
      AND maximum_age IS NULL
      AND gender IN ('male','female')   -- only male & female rows
    GROUP BY zipcode
) AS p
ON z.zipcode = p.zipcode
WHERE
  -- keep ZIPs whose polygon is within 10 000 m of the given point
  ST_DWITHIN(
      ST_GEOGFROMTEXT(z.zipcode_geom),              -- ZIP polygon
      ST_GEOGPOINT(-122.3321, 47.6062),             -- (lon, lat)
      10000                                         -- distance in meters
  );