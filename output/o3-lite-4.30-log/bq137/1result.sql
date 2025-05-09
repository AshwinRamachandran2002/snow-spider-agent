SELECT
  za.zipcode_geom  AS polygon,
  za.area_land_meters  AS land_area_m2,
  za.area_water_meters AS water_area_m2,
  za.latitude,
  za.longitude,
  za.state_code,
  za.state_name,
  za.city,
  za.county,
  SUM(pop.population) AS total_population
FROM `bigquery-public-data.utility_us.zipcode_area` AS za
JOIN `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS pop
  ON pop.zipcode = za.zipcode
WHERE pop.gender IN ('male','female')
  AND pop.minimum_age IS NULL
  AND pop.maximum_age IS NULL
  AND ST_DWITHIN(
        ST_GEOGFROMTEXT(za.zipcode_geom),
        ST_GEOGPOINT(-122.3321, 47.6062),
        10000
      )
GROUP BY
  za.zipcode_geom,
  za.area_land_meters,
  za.area_water_meters,
  za.latitude,
  za.longitude,
  za.state_code,
  za.state_name,
  za.city,
  za.county
ORDER BY total_population DESC;