-- ZIP code areas within 10 km of (-122.3321 lon , 47.6062 lat)  
-- together with land / water area, centroid, place info and 2010 total population
SELECT
  z.zipcode,                       -- 5–digit ZIP Code
  z.zipcode_geom        AS polygon,
  z.area_land_meters,
  z.area_water_meters,
  z.latitude,
  z.longitude,
  z.state_code,
  z.state_name,
  z.city,
  z.county,
  COALESCE(p.total_population,0) AS total_population
FROM `bigquery-public-data.utility_us.zipcode_area`   AS z
LEFT JOIN (
  SELECT
    LPAD(zipcode,5,'0')            AS zipcode,         -- ensure leading‑zero ZIPs match
    SUM(population)                AS total_population
  FROM `bigquery-public-data.census_bureau_usa.population_by_zip_2010`
  WHERE
    minimum_age IS NULL            -- no age constraints
    AND maximum_age IS NULL
    AND gender IN ('male','female')-- only male + female rows
  GROUP BY zipcode
) AS p
ON z.zipcode = p.zipcode
WHERE
  z.zipcode_geom IS NOT NULL
  AND ST_DWITHIN(
        ST_GEOGFROMTEXT(z.zipcode_geom),              -- ZIP polygon
        ST_GEOGPOINT(-122.3321, 47.6062),             -- Seattle coordinates (lon, lat)
        10000                                         -- 10 000 metres = 10 km
      );