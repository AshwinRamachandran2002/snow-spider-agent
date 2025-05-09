SELECT
  z.zipcode,
  z.polygon,
  z.area_land_meters,
  z.area_water_meters,
  ROUND(z.latitude, 4) AS latitude,
  ROUND(z.longitude, 4) AS longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  p.total_population
FROM (
  SELECT
    *,
    SAFE.ST_GEOGFROMTEXT(zipcode_geom) AS polygon
  FROM `bigquery-public-data.utility_us.zipcode_area`
) AS z
JOIN (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE
    minimum_age IS NULL
    AND maximum_age IS NULL
    AND gender IN ('male', 'female')
  GROUP BY zipcode
) AS p
ON z.zipcode = p.zipcode
WHERE
  z.polygon IS NOT NULL
  AND ST_DWithin(z.polygon, ST_GEOGPOINT(-122.3321, 47.6062), 10000)