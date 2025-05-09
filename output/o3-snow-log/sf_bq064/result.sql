/* 1. ZIP codes whose centroids lie within 5 miles of the specified point */
WITH near_zips AS (
    SELECT
        "zip_code"
    FROM CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE ST_DISTANCE(
              TO_GEOGRAPHY(ST_POINT("internal_point_lon", "internal_point_lat")),
              TO_GEOGRAPHY(ST_POINT(-122.191667, 47.685833))
          ) <= 5 * 1609.34          -- 5 miles in metres
)

/* 2. Combine with ACS ZIP-level population and income, then present results */
SELECT
    nz."zip_code",
    ROUND(CAST(zc."total_pop"         AS FLOAT), 1) AS "total_population",
    ROUND(CAST(zc."income_per_capita" AS FLOAT), 1) AS "average_individual_income"
FROM near_zips nz
JOIN CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR zc
      ON zc."geo_id" = nz."zip_code"
ORDER BY "average_individual_income" DESC NULLS LAST;