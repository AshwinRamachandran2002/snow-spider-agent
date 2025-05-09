-- ZIP code areas within 10 km of (-122.3321  47.6062) with 2010 Census population
WITH
/* 1. 2010 population – only male & female, no age limits */
pop AS (
    SELECT
        "zipcode",
        SUM("population") AS "total_population"
    FROM CENSUS_BUREAU_USA.CENSUS_BUREAU_USA."POPULATION_BY_ZIP_2010"
    WHERE "minimum_age" IS NULL
      AND "maximum_age" IS NULL
      AND LOWER("gender") IN ('male','female')
    GROUP BY "zipcode"
),

/* 2. ZIP areas whose polygon is ≤10 000 m from the reference point */
nearby_zips AS (
    SELECT *
    FROM CENSUS_BUREAU_USA.UTILITY_US."ZIPCODE_AREA"
    WHERE ST_DISTANCE(
              TO_GEOGRAPHY("zipcode_geom"),
              TO_GEOGRAPHY('POINT (-122.3321 47.6062)')
          ) <= 10000      -- metres (10 km)
)

SELECT
    z."zipcode_geom"      AS "polygon_wkt",
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county",
    COALESCE(p."total_population", 0) AS "total_population"
FROM nearby_zips z
LEFT JOIN pop p
       ON z."zipcode" = p."zipcode";