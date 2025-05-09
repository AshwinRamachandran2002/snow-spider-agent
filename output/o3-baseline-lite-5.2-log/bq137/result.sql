-- zip codes within 10 km of (-122.3321 lon, 47.6062 lat) with 2010 gender‑specific
-- total population and zipcode‐area attributes
WITH gender_tot_pop AS (
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL           -- all ages
    AND maximum_age IS NULL           -- all ages
    AND gender IN ('male','female')   -- keep only sex‑specific totals
  GROUP BY zipcode
)
SELECT
  z.zipcode,
  zipcode_geom,                      -- polygon (GEOGRAPHY)
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  COALESCE(p.total_population,0) AS total_population
FROM (
  SELECT
    zipcode,
    SAFE.ST_GEOGFROMTEXT(zipcode_geom) AS zipcode_geom,
    area_land_meters,
    area_water_meters,
    latitude,
    longitude,
    state_code,
    state_name,
    city,
    county
  FROM `bigquery-public-data.utility_us.zipcode_area`
) AS z
LEFT JOIN gender_tot_pop AS p
USING (zipcode)
WHERE ST_DWITHIN(
        z.zipcode_geom,
        ST_GEOGPOINT(-122.3321, 47.6062),   -- Seattle downtown
        10000                               -- 10 km radius (meters)
      )
ORDER BY total_population DESC, zipcode;