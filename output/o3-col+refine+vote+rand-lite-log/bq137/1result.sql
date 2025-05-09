-- Zip code areas within 10 km of (-122.3321, 47.6062) with 2010 population totals
WITH pop_2010 AS (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL
    AND maximum_age IS NULL
    AND gender IN ('male', 'female')        -- only male & female totals
  GROUP BY zipcode
)

SELECT
  z.zipcode,
  z.zipcode_geom              AS polygon,          -- WKT polygon string
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
JOIN pop_2010 AS p
USING (zipcode)
WHERE ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),           -- ZIP polygon
        ST_GEOGPOINT(-122.3321, 47.6062),          -- reference point
        10000                                      -- 10 km radius (meters)
      )
ORDER BY p.total_population DESC;