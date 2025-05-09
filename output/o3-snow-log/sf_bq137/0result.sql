WITH "POP_2010_AGG" AS (
    SELECT
        "zipcode",
        SUM("population") AS "total_population"
    FROM CENSUS_BUREAU_USA.CENSUS_BUREAU_USA."POPULATION_BY_ZIP_2010"
    WHERE "gender" IN ('male','female')
      AND "minimum_age" IS NULL
      AND "maximum_age" IS NULL
    GROUP BY "zipcode"
),
"ZIPCODES_WITHIN_10KM" AS (
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
        z."county"
    FROM CENSUS_BUREAU_USA.UTILITY_US."ZIPCODE_AREA"      AS z
    WHERE ST_DISTANCE(
              TO_GEOGRAPHY(z."zipcode_geom"),
              TO_GEOGRAPHY('POINT(-122.3321 47.6062)')
          ) <= 10000   -- 10 km in metres
)
SELECT
    w."zipcode_geom",
    w."area_land_meters",
    w."area_water_meters",
    w."latitude",
    w."longitude",
    w."state_code",
    w."state_name",
    w."city",
    w."county",
    COALESCE(p."total_population",0) AS "total_population"
FROM "ZIPCODES_WITHIN_10KM" w
LEFT JOIN "POP_2010_AGG" p
       ON w."zipcode" = p."zipcode"
ORDER BY "total_population" DESC NULLS LAST;