SELECT
    z."zipcode_geom" AS "polygon",
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
    "CENSUS_BUREAU_USA"."UTILITY_US"."ZIPCODE_AREA" AS z
JOIN
    "CENSUS_BUREAU_USA"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010" AS p
    ON z."zipcode" = p."zipcode"
WHERE
    p."gender" IN ('male', 'female') AND
    ST_DWithin(
        ST_GeogFromText(z."zipcode_geom"),
        ST_MakePoint(-122.3321, 47.6062),
        10000
    )
GROUP BY
    z."zipcode_geom",
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county";