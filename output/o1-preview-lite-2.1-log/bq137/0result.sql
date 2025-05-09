SELECT 
  z.zipcode,
  z.zipcode_geom,
  z.area_land_meters,
  z.area_water_meters,
  ROUND(z.latitude, 4) AS latitude,
  ROUND(z.longitude, 4) AS longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  p.population
FROM 
  `bigquery-public-data.utility_us.zipcode_area` AS z
LEFT JOIN 
  (
    SELECT zipcode, population
    FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
    WHERE gender IS NULL AND minimum_age IS NULL
  ) AS p
ON z.zipcode = p.zipcode
WHERE 
  ST_DWithin(
    ST_GEOGFROMTEXT(z.zipcode_geom),
    ST_GEOGPOINT(-122.3321, 47.6062),
    10000
  )