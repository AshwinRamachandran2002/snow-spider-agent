SELECT
  z.zipcode_geom                           AS polygon,
  z.area_land_meters                       AS land_area_m2,
  z.area_water_meters                      AS water_area_m2,
  ROUND(z.latitude, 4)                     AS latitude,
  ROUND(z.longitude, 4)                    AS longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  SUM(p.population)                        AS total_population
FROM `bigquery-public-data.utility_us.zipcode_area` AS z
JOIN `bigquery-public-data.census_bureau_usa.population_by_zip_2010` AS p
  ON z.zipcode = LPAD(p.zipcode, 5, '0')
WHERE p.gender IN ('male', 'female')
  AND p.minimum_age IS NULL
  AND p.maximum_age IS NULL
  AND ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),
        ST_GEOGPOINT(-122.3321, 47.6062),
        10000           -- 10 km in meters
      )
GROUP BY
  z.zipcode_geom,
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county
ORDER BY
  total_population DESC;