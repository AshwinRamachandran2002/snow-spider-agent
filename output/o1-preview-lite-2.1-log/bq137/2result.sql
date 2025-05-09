SELECT
  z.zipcode,
  ST_GeogFromText(z.zipcode_geom) AS zipcode_geom,
  z.area_land_meters,
  z.area_water_meters,
  ROUND(z.latitude, 4) AS latitude,
  ROUND(z.longitude, 4) AS longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  p.population
FROM `bigquery-public-data.utility_us.zipcode_area` AS z
LEFT JOIN (
  SELECT zipcode, population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL AND maximum_age IS NULL AND gender IS NULL
) AS p
ON z.zipcode = p.zipcode
WHERE ST_DWithin(
  ST_GeogFromText(z.zipcode_geom),
  ST_GeogPoint(-122.3321, 47.6062),
  10000
)