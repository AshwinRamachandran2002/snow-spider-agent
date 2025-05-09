-- All ZIP code areas whose centroid is within 10 km of (-122.3321 , 47.6062),
-- enriched with 2010 total population (male+female, all ages) and ZIP metadata
WITH pop_2010 AS (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE gender IN ('male','female')
    AND minimum_age IS NULL   -- keep only total-age rows
    AND maximum_age IS NULL
  GROUP BY zipcode
)

SELECT
  z.zipcode,
  z.zipcode_geom            AS polygon,
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
        ST_CENTROID(ST_GEOGFROMTEXT(z.zipcode_geom)),
        ST_GEOGPOINT(-122.3321, 47.6062),   -- Seattle location
        10000                               -- 10 km radius
      )
ORDER BY z.zipcode;