WITH "POP10" AS (
    SELECT
        "zipcode",
        SUM("population") AS "total_population"
    FROM CENSUS_BUREAU_USA.CENSUS_BUREAU_USA."POPULATION_BY_ZIP_2010"
    WHERE LOWER("gender") IN ('male','female')
      AND "minimum_age" IS NULL
      AND "maximum_age" IS NULL
    GROUP BY "zipcode"
)
SELECT
    ZA."zipcode_geom"     AS "polygon",
    ZA."area_land_meters",
    ZA."area_water_meters",
    ZA."latitude",
    ZA."longitude",
    ZA."state_code",
    ZA."state_name",
    ZA."city",
    ZA."county",
    P."total_population"
FROM CENSUS_BUREAU_USA.UTILITY_US."ZIPCODE_AREA" AS ZA
JOIN "POP10" P
  ON ZA."zipcode" = P."zipcode"
WHERE ST_DISTANCE(
          TO_GEOGRAPHY(ZA."zipcode_geom"),
          TO_GEOGRAPHY('POINT(-122.3321 47.6062)')
      ) <= 10000;