/* --------------------------------------------------------------------------
   1.  Get ZIP-code centroids that fall within a 5-mile (8 046.72 m) radius
       of the point 47.685833 °N, –122.191667 °W.                    
   2.  Retrieve population and per-capita-income figures for those ZIPs from
       the 2015 5-year ACS ZIP-code table.  Per-capita income is already the
       average individual income.                                          
   3.  Round results to one decimal place and order by income.              
---------------------------------------------------------------------------*/
WITH target AS (  -- point of interest
    SELECT TO_GEOGRAPHY('POINT(-122.191667 47.685833)') AS g
),

candidate_zips AS (   -- ZIP centroids within 5 miles of the point
    SELECT
        z."zip_code"
    FROM CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES.ZIP_CODES z
    CROSS JOIN target t
    WHERE ST_DISTANCE(
              ST_MAKEPOINT(z."internal_point_lon", z."internal_point_lat"),
              t.g
          ) <= 8046.72          -- 5 miles in metres
)

SELECT
    c."zip_code"                                           AS "ZIP_CODE",
    ROUND(CAST(a."total_pop"        AS NUMBER), 1)         AS "total_population",
    ROUND(CAST(a."income_per_capita" AS NUMBER), 1)        AS "average_individual_income"
FROM   candidate_zips                                            c
JOIN   CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR  a
       ON a."geo_id" = c."zip_code"
ORDER  BY "average_individual_income" DESC NULLS LAST;