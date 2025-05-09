WITH zip_stats AS (   -- population & income by ZIP (2015 ACS)
    SELECT
        "geo_id"               AS "zip_code",
        "total_pop"::FLOAT     AS "total_pop",
        "income_per_capita"::FLOAT AS "avg_income"
    FROM CENSUS_BUREAU_ACS_1.CENSUS_BUREAU_ACS."ZIP_CODES_2015_5YR"
),
zip_centroids AS (   -- centroids / internal points for each ZIP
    SELECT
        "zip_code",
        "internal_point_lat"::FLOAT  AS lat,
        "internal_point_lon"::FLOAT  AS lon
    FROM CENSUS_BUREAU_ACS_1.GEO_US_BOUNDARIES."ZIP_CODES"
),
within_radius AS (   -- keep ZIPs whose centroid is within 5 miles of the WA point
    SELECT
        zs."zip_code",
        ROUND(zs."total_pop", 1)      AS total_pop,
        ROUND(zs."avg_income", 1)     AS average_individual_income
    FROM zip_stats    zs
    JOIN zip_centroids zc
      ON zs."zip_code" = zc."zip_code"
    WHERE ST_DISTANCE(
              ST_MAKEPOINT(-122.191667, 47.685833),   -- reference point
              ST_MAKEPOINT(zc.lon, zc.lat)
          ) <= 5 * 1609.34                           -- 5 miles in metres
)
SELECT
    "zip_code",
    total_pop,
    average_individual_income
FROM within_radius
ORDER BY average_individual_income DESC NULLS LAST;