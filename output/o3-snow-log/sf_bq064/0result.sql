/*  Join ZIP‐code geometry (lat/lon) with ACS demographic values,
    keep only ZIPs within 5 miles (8 046.72 m) of the reference point,
    then return total population and average individual income          */
WITH zip_demo AS (
    SELECT
        g."zip_code"                                                      AS "zip_code",
        CAST(a."total_pop"        AS FLOAT)                               AS "total_population",
        CAST(a."income_per_capita" AS FLOAT)                              AS "income_per_capita",
        ST_MAKEPOINT(g."internal_point_lon", g."internal_point_lat")      AS "centroid"
    FROM CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES.ZIP_CODES                  g
    JOIN CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR         a
          ON g."zip_code" = a."geo_id"
)
SELECT
    "zip_code",
    ROUND("total_population", 1)         AS "total_population",
    ROUND("income_per_capita", 1)        AS "avg_individual_income"
FROM zip_demo
WHERE ST_DISTANCE(
          "centroid",
          ST_MAKEPOINT(-122.191667, 47.685833)   -- target point
      ) <= 8046.72                               -- 5 miles in metres
ORDER BY "avg_individual_income" DESC NULLS LAST;