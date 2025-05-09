-- 10-km radius around (-122.3321, 47.6062) – ZIP polygons, attributes & 2010 male+female totals
SELECT
  z.zipcode,
  z.zipcode_geom            AS polygon,      -- original WKT polygon for the ZIP
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  SUM(p.population)         AS total_population_2010
FROM `bigquery-public-data.utility_us.zipcode_area`            AS z
JOIN `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  ON z.zipcode = p.zipcode
WHERE ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),     -- ZIP polygon
        ST_GEOGPOINT(-122.3321, 47.6062),    -- target point (lon, lat)
        10000                                -- 10 000 m (10 km) buffer
      )
  AND p.gender IN ('male', 'female')         -- include only male & female rows
  AND p.minimum_age IS NULL                  -- overall totals (no age limits)
  AND p.maximum_age IS NULL
GROUP BY
  z.zipcode,
  z.zipcode_geom,
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county
ORDER BY total_population_2010 DESC;