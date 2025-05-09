-- Zip-code polygons within 10 km of (-122.3321 lon, 47.6062 lat)  
-- with 2010 (male + female, all-ages) population totals
WITH pop2010 AS (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL        -- “all ages” rows
    AND maximum_age IS NULL
    AND gender IN ('male','female') -- keep only male & female totals
  GROUP BY zipcode
)

SELECT
  z.zipcode_geom           AS polygon,
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  p.total_population
FROM pop2010 AS p
JOIN `bigquery-public-data.utility_us.zipcode_area` AS z
  ON z.zipcode = p.zipcode
WHERE ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),        -- ZIP-code polygon
        ST_GEOGPOINT(-122.3321, 47.6062),       -- reference point
        10000                                   -- 10 000 m radius
      )
ORDER BY total_population DESC;