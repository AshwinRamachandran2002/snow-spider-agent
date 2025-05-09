SELECT
  z.zipcode,
  ANY_VALUE(ST_GEOGFROMTEXT(z.zipcode_geom)) AS polygon,
  ANY_VALUE(z.area_land_meters) AS area_land_meters,
  ANY_VALUE(z.area_water_meters) AS area_water_meters,
  ANY_VALUE(z.latitude) AS latitude,
  ANY_VALUE(z.longitude) AS longitude,
  ANY_VALUE(z.state_code) AS state_code,
  ANY_VALUE(z.state_name) AS state_name,
  ANY_VALUE(z.city) AS city,
  ANY_VALUE(z.county) AS county,
  SUM(p.population) AS total_population
FROM `bigquery-public-data.utility_us.zipcode_area` AS z
LEFT JOIN `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  ON z.zipcode = p.zipcode
     AND p.gender IN ('male', 'female')
     AND p.minimum_age IS NULL
WHERE ST_DWithin(
  ST_GEOGFROMTEXT(z.zipcode_geom),
  ST_GEOGPOINT(-122.3321, 47.6062),
  10000
)
GROUP BY
  z.zipcode