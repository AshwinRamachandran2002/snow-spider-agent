WITH pop2010 AS (
  SELECT
    LPAD(zipcode, 5, '0') AS zipcode,
    SUM(population)       AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL
    AND maximum_age IS NULL
    AND gender IN ('male', 'female')
  GROUP BY zipcode
)
SELECT
  z.zipcode_geom  AS polygon,
  z.area_land_meters  AS land_area_m2,
  z.area_water_meters AS water_area_m2,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  p.total_population
FROM `bigquery-public-data.utility_us.zipcode_area` AS z
JOIN pop2010 AS p
  ON z.zipcode = p.zipcode
WHERE ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),
        ST_GEOGPOINT(-122.3321, 47.6062),
        10000
      )
ORDER BY p.total_population DESC;