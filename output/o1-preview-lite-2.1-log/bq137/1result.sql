SELECT
  z.zipcode,
  ST_GEOGFROMTEXT(z.zipcode_geom) AS zipcode_geom,
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
  `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
ON
  z.zipcode = p.zipcode
WHERE
  ST_DWITHIN(
    ST_GEOGFROMTEXT(z.zipcode_geom),
    ST_GEOGPOINT(-122.3321, 47.6062),
    10000
  )
  AND (p.gender IS NULL OR p.gender = '')
  AND p.minimum_age IS NULL;