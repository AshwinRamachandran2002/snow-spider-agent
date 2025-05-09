WITH "POP_2010" AS (   -- total 2010 population per ZIP (male + female, all ages)
    SELECT 
        "zipcode",
        SUM("population") AS "total_population"
    FROM CENSUS_BUREAU_USA.CENSUS_BUREAU_USA."POPULATION_BY_ZIP_2010"
    WHERE 
        "minimum_age" IS NULL                 -- no age breakdown
        AND "maximum_age" IS NULL
        AND LOWER("gender") IN ('male','female')   -- keep only male / female totals
    GROUP BY "zipcode"
)

SELECT 
    z."zipcode_geom",          -- polygon (WKT)
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county",
    p."total_population"
FROM CENSUS_BUREAU_USA.UTILITY_US."ZIPCODE_AREA"   z
JOIN "POP_2010"                                    p  ON p."zipcode" = z."zipcode"
WHERE 
    ST_DISTANCE(
        TO_GEOGRAPHY(z."zipcode_geom"),
        TO_GEOGRAPHY('POINT(-122.3321 47.6062)')
    ) <= 10000          -- 10 km (distance returned in metres)
ORDER BY 
    p."total_population" DESC NULLS LAST;