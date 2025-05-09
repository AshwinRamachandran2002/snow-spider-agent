-- ZIP code areas within 10 km of (-122.3321, 47.6062) with 2010 total (male+female) population
SELECT
  z.zipcode,
  z.zipcode_geom              AS polygon,          -- WKT of ZIP polygon
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  p.total_population
FROM `bigquery-public-data.utility_us.zipcode_area` AS z
JOIN (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IN ('male', 'female')
    AND minimum_age IS NULL
    AND maximum_age IS NULL
  GROUP BY zipcode
) AS p
ON z.zipcode = p.zipcode
WHERE ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),           -- ZIP geometry
        ST_GEOGPOINT(-122.3321, 47.6062),          -- reference point (lon, lat)
        10000                                      -- 10 000 m radius
      );