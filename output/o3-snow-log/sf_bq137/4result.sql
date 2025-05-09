WITH "population_per_zip" AS (
    SELECT
        "zipcode",
        SUM("population") AS "total_population"
    FROM "CENSUS_BUREAU_USA"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010"
    WHERE "gender" IN ('male', 'female')
      AND "minimum_age" IS NULL
      AND "maximum_age" IS NULL
    GROUP BY "zipcode"
)

SELECT
    z."zipcode_geom"  AS "polygon",
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county",
    p."total_population"
FROM "CENSUS_BUREAU_USA"."UTILITY_US"."ZIPCODE_AREA" AS z
JOIN "population_per_zip"                       AS p
  ON z."zipcode" = p."zipcode"
WHERE ST_DISTANCE(
          TO_GEOGRAPHY(z."zipcode_geom"),
          TO_GEOGRAPHY('POINT (-122.3321 47.6062)')
      ) <= 10000;