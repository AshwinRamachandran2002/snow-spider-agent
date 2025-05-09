SELECT z."zipcode", z."zipcode_geom", z."area_land_meters", z."area_water_meters",
       ROUND(z."latitude", 4) AS "latitude", ROUND(z."longitude", 4) AS "longitude",
       z."state_code", z."state_name", z."city", z."county",
       SUM(p."population") AS "population"
FROM "CENSUS_BUREAU_USA"."UTILITY_US"."ZIPCODE_AREA" z
JOIN "CENSUS_BUREAU_USA"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010" p
    ON z."zipcode" = p."zipcode"
WHERE ST_DWITHIN(
        ST_MAKEPOINT(z."longitude", z."latitude"),
        ST_MAKEPOINT(-122.3321, 47.6062),
        10000.0
    )
GROUP BY z."zipcode", z."zipcode_geom", z."area_land_meters", z."area_water_meters",
         z."latitude", z."longitude", z."state_code", z."state_name", z."city", z."county";