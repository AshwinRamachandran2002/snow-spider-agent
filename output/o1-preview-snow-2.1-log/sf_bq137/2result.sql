SELECT
    za."zipcode",
    za."zipcode_geom",
    ROUND(za."area_land_meters", 4) AS "area_land_meters",
    ROUND(za."area_water_meters", 4) AS "area_water_meters",
    ROUND(za."latitude", 4) AS "latitude",
    ROUND(za."longitude", 4) AS "longitude",
    za."state_code",
    za."state_name",
    za."city",
    za."county",
    COALESCE(p."population", 0) AS "population"
FROM
    "CENSUS_BUREAU_USA"."UTILITY_US"."ZIPCODE_AREA" za
LEFT JOIN (
    SELECT
        "zipcode",
        SUM("population") AS "population"
    FROM
        "CENSUS_BUREAU_USA"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010"
    GROUP BY
        "zipcode"
) p ON za."zipcode" = p."zipcode"
WHERE
    ST_DWITHIN(
        ST_GEOGFROMTEXT(za."zipcode_geom"),
        ST_MAKEPOINT(-122.3321, 47.6062),
        10000
    );