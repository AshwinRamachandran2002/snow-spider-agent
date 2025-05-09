SELECT
    za."zipcode",
    za."zipcode_geom" AS "polygon",
    za."area_land_meters" AS "land_area_meters",
    za."area_water_meters" AS "water_area_meters",
    ROUND(za."latitude", 4) AS "latitude",
    ROUND(za."longitude", 4) AS "longitude",
    za."state_code",
    za."state_name",
    za."city",
    za."county",
    COALESCE(SUM(pz."population"), 0) AS "total_population"
FROM
    "CENSUS_BUREAU_USA"."UTILITY_US"."ZIPCODE_AREA" AS za
LEFT JOIN
    "CENSUS_BUREAU_USA"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010" AS pz
    ON za."zipcode" = pz."zipcode" AND LOWER(TRIM(pz."gender")) IN ('male', 'female')
WHERE
    ST_DWithin(
        ST_GeogFromText(za."zipcode_geom"),
        ST_MakePoint(-122.3321, 47.6062),
        10000  -- 10 kilometers
    )
GROUP BY
    za."zipcode",
    za."zipcode_geom",
    za."area_land_meters",
    za."area_water_meters",
    za."latitude",
    za."longitude",
    za."state_code",
    za."state_name",
    za."city",
    za."county";