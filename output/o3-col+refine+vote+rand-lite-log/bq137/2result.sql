-- Zip-code areas within 10 km of (-122.3321, 47.6062) with 2010 male+female population totals
WITH target_zips AS (
  SELECT *
  FROM `bigquery-public-data.utility_us.zipcode_area`
  WHERE ST_DWITHIN(
          ST_GEOGFROMTEXT(zipcode_geom),           -- ZIP polygon
          ST_GEOGPOINT(-122.3321, 47.6062),        -- reference point (Seattle)
          10000                                    -- 10 000 m radius
        )
),
tot_pop_2010 AS (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL            -- no age limits (totals)
    AND maximum_age IS NULL
    AND gender IN ('male', 'female')   -- only male + female rows
  GROUP BY zipcode
)
SELECT
  t.zipcode_geom              AS zipcode_polygon,
  t.area_land_meters,
  t.area_water_meters,
  t.latitude,
  t.longitude,
  t.state_code,
  t.state_name,
  t.city,
  t.county,
  p.total_population
FROM target_zips AS t
LEFT JOIN tot_pop_2010 AS p
USING (zipcode)
ORDER BY total_population DESC;