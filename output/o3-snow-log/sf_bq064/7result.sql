/*---------------------------------------------------------------------------
  1.  Start from the ACS 2015-5YR ZIP-code table that already contains
      total population and per-capita income.
  2.  Keep only ZIP codes whose internal point is within a 5-mile
      (8 046.72 m) radius of the point 47.685833 N, -122.191667 W.
  3.  Return total population (1 decimal) and average individual income
      (1 decimal) sorted by income, highest first.
---------------------------------------------------------------------------*/
WITH "ZIP_DATA" AS (     -- population and income
    SELECT
        "geo_id"                            AS "ZIP_CODE",
        CAST("total_pop"         AS DOUBLE) AS "TOTAL_POP",
        CAST("income_per_capita" AS DOUBLE) AS "INCOME_PER_CAPITA"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS.ZIP_CODES_2015_5YR
),
"NEARBY_ZIPS" AS (       -- ZIPs whose centroid is within 5 miles
    SELECT
        g."zip_code"                      AS "ZIP_CODE"
    FROM CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES.ZIP_CODES g
    WHERE ST_DISTANCE(
              ST_MAKEPOINT(g."internal_point_lon", g."internal_point_lat"),
              ST_MAKEPOINT(-122.191667 , 47.685833)
          ) <= 8046.72        -- 5 miles expressed in metres
)
SELECT
    d."ZIP_CODE",
    ROUND(d."TOTAL_POP",        1) AS "TOTAL_POPULATION",
    ROUND(d."INCOME_PER_CAPITA", 1) AS "AVERAGE_INDIVIDUAL_INCOME"
FROM "ZIP_DATA"  d
JOIN "NEARBY_ZIPS" n
  ON d."ZIP_CODE" = n."ZIP_CODE"
ORDER BY "AVERAGE_INDIVIDUAL_INCOME" DESC NULLS LAST;