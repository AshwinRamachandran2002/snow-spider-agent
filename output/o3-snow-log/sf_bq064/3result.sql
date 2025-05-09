/*--------------------------------------------
  1.  Create the target point (lat, lon) as a GEOGRAPHY object
  2.  Build a list of ZIP codes whose internal centroid
      lies within 5 miles (≈ 8 046.72 metres) of that point
  3.  Pull 2015-5-YR ACS population & per-capita-income
      for those ZIPs and calculate total income
  4.  Aggregate by ZIP: 
        • total population
        • average individual income  =  Σ (total_income) / Σ (population)
  5.  Return results ordered by income (desc)
---------------------------------------------*/
WITH target_point AS (
    SELECT ST_POINT(-122.191667, 47.685833)         AS geom          -- lon, lat
),
zips_in_radius AS (
    SELECT
        g."zip_code"
    FROM CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES.ZIP_CODES   g,
         target_point                                      t
    WHERE ST_DISTANCE(
              ST_POINT(g."internal_point_lon", g."internal_point_lat"),
              t.geom
          ) <= 8046.72                                    -- 5 miles in metres
),
zip_stats AS (
    SELECT
        s."geo_id"                                                             AS zip_code,
        CAST(s."total_pop"         AS FLOAT)                                   AS population,
        CAST(s."income_per_capita" AS FLOAT)                                   AS per_capita_income,
        CAST(s."total_pop" AS FLOAT) * CAST(s."income_per_capita" AS FLOAT)    AS total_income
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR  s
)
SELECT
    z."zip_code",
    SUM(s.population)                                                AS total_population,
    ROUND( SUM(s.total_income) / NULLIF( SUM(s.population), 0 ), 1 ) AS average_individual_income
FROM zips_in_radius          z
JOIN zip_stats               s  ON s.zip_code = z."zip_code"
GROUP BY z."zip_code"
ORDER BY average_individual_income DESC NULLS LAST;