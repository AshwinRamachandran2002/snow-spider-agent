/*  Zip codes whose polygons fall within 10 000 m of
    (-122.3321 , 47.6062)  (Seattle downtown),
    along with 2010 Census population (male+female totals)
    and zipcode‑area attributes                                      */
WITH pop_2010 AS (                     -- male + female, all ages
  SELECT
    zipcode,
    SUM(population) AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL
    AND maximum_age IS NULL
    AND gender IN ('male', 'female')   -- exclude overall totals (gender IS NULL)
  GROUP BY zipcode
),
zips AS (                              -- convert WKT → GEOGRAPHY safely
  SELECT
    zipcode,
    SAFE.ST_GEOGFROMTEXT(zipcode_geom) AS geom,
    area_land_meters,
    area_water_meters,
    latitude,
    longitude,
    state_code,
    state_name,
    city,
    county
  FROM `bigquery-public-data.utility_us.zipcode_area`
),
nearby_zips AS (                       -- keep only polygons within 10 km
  SELECT *
  FROM zips
  WHERE geom IS NOT NULL
    AND ST_DWITHIN(
          geom,
          ST_GEOGPOINT(-122.3321, 47.6062),   -- reference point
          10000                               -- metres
        )
)
SELECT
  nz.geom               AS zipcode_polygon,
  nz.area_land_meters,
  nz.area_water_meters,
  nz.latitude,
  nz.longitude,
  nz.state_code,
  nz.state_name,
  nz.city,
  nz.county,
  p.total_population
FROM nearby_zips AS nz
JOIN pop_2010   AS p
  USING (zipcode)
ORDER BY total_population DESC;