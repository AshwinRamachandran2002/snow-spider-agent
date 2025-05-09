WITH tracts_within_radius AS (
    SELECT
        g."geo_id",
        t."total_pop",
        t."income_per_capita",
        g."tract_geom"
    FROM
        "CENSUS_BUREAU_ACS_1"."GEO_CENSUS_TRACTS"."CENSUS_TRACTS_WASHINGTON" g
        JOIN "CENSUS_BUREAU_ACS_1"."CENSUS_BUREAU_ACS"."CENSUSTRACT_2017_5YR" t
            ON g."geo_id" = t."geo_id"
    WHERE
        ST_DISTANCE(
            ST_GEOGRAPHYFROMWKB(g."internal_point_geo"),
            ST_POINT(-122.191667, 47.685833)
        ) <= 8046.72  -- 5 miles in meters
)
SELECT
    z."zip_code",
    ROUND(SUM(twr."total_pop"), 4) AS "Population",
    ROUND(
        SUM(twr."income_per_capita" * twr."total_pop") /
        NULLIF(SUM(twr."total_pop"), 0), 4
    ) AS "Average_Individual_Income"
FROM
    tracts_within_radius twr
    JOIN "CENSUS_BUREAU_ACS_1"."GEO_US_BOUNDARIES"."ZIP_CODES" z
        ON z."state_name" = 'Washington'
        AND ST_INTERSECTS(
            ST_GEOGRAPHYFROMWKB(z."zip_code_geom"),
            ST_GEOGRAPHYFROMWKB(twr."tract_geom")
        )
GROUP BY
    z."zip_code"
ORDER BY
    "Average_Individual_Income" DESC NULLS LAST;