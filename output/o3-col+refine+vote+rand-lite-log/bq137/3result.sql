WITH pop AS (  -- 1. 2010 Census: total (male + female) population, all ages, per ZIP
  SELECT
    LPAD(zipcode, 5, '0') AS zipcode,        -- pad to 5-digits so it matches zipcode_area
    SUM(population)       AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE minimum_age IS NULL                -- no age-range rows (i.e., totals)
    AND maximum_age IS NULL
    AND LOWER(gender) IN ('male', 'female') -- keep only male + female
  GROUP BY zipcode
)

SELECT
  z.zipcode_geom          AS zipcode_polygon,   -- polygon (as WKT text)
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
JOIN pop AS p
  ON z.zipcode = p.zipcode                     -- inner-join keeps only ZIPs with pop data
WHERE ST_DWITHIN(                              -- 10-km radius of (-122.3321, 47.6062)
        ST_GEOGFROMTEXT(z.zipcode_geom),       -- convert WKT to GEOGRAPHY
        ST_GEOGPOINT(-122.3321, 47.6062),
        10000                                   -- meters
      );