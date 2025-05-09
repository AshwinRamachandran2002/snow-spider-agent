-- Zip code areas within 10 km of (-122.3321 , 47.6062)  
-- together with 2010 census (male + female, all ages) population totals
WITH pop10 AS (               -- 2010 population by ZIP (male + female, no age limits)
  SELECT
    LPAD(zipcode, 5, '0')        AS zipcode,
    SUM(population)              AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL               -- totals (no age range)
    AND maximum_age IS NULL
    AND gender IN ('male','female')       -- keep only male + female totals
  GROUP BY zipcode
),
zip_geom AS (                 -- all ZIP polygons with attributes
  SELECT
    z.zipcode,
    ST_GEOGFROMTEXT(z.zipcode_geom) AS geom,
    z.area_land_meters,
    z.area_water_meters,
    z.latitude,
    z.longitude,
    z.state_code,
    z.state_name,
    z.city,
    z.county
  FROM `bigquery-public-data.utility_us.zipcode_area` AS z
  WHERE z.zipcode_geom IS NOT NULL
),
nearby AS (                    -- only ZIPs within 10 000 m (10 km) of the point
  SELECT *
  FROM zip_geom
  WHERE ST_DWITHIN(
          geom,
          ST_GEOGPOINT(-122.3321, 47.6062),   -- (lon , lat)
          10000                                -- distance in meters
        )
)
SELECT
  n.zipcode,                    -- ZIP code identifier
  n.geom          AS zipcode_polygon,   -- polygon geography
  n.area_land_meters,
  n.area_water_meters,
  n.latitude,
  n.longitude,
  n.state_code,
  n.state_name,
  n.city,
  n.county,
  COALESCE(p.total_population,0) AS total_population
FROM nearby AS n
LEFT JOIN pop10 AS p
ON n.zipcode = p.zipcode
ORDER BY n.zipcode;