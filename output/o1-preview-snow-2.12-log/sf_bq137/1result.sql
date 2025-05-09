SELECT
    z."zipcode",
    z."zipcode_geom",
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county",
    SUM(p."population") AS "total_population"
FROM
    "CENSUS_BUREAU_USA"."UTILITY_US"."ZIPCODE_AREA" z
JOIN
    "CENSUS_BUREAU_USA"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010" p
    ON z."zipcode" = p."zipcode"
WHERE
    p."gender" IN ('male', 'female')
    AND TRY_TO_GEOGRAPHY(z."zipcode_geom") IS NOT NULL
    AND ST_DWITHIN(
        TRY_TO_GEOGRAPHY(z."zipcode_geom"),
        ST_MAKEPOINT(-122.3321, 47.6062),
        10000
    )
GROUP BY
    z."zipcode",
    z."zipcode_geom",
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county";