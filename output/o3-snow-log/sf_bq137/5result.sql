WITH POP_2010 AS (
    /* 2010 population totals – sum male + female where the row itself
       represents the whole-age total (minimum_age & maximum_age are NULL) */
    SELECT
        "zipcode",
        SUM("population")                AS "total_population"
    FROM  "CENSUS_BUREAU_USA"."CENSUS_BUREAU_USA"."POPULATION_BY_ZIP_2010"
    WHERE "minimum_age" IS NULL
      AND "maximum_age" IS NULL
      AND "gender" IN ('male','female')
    GROUP BY "zipcode"
),
ZIP_AREAS AS (
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
    FROM  "CENSUS_BUREAU_USA"."UTILITY_US"."ZIPCODE_AREA"  z
),
CENTER_POINT AS (          -- reference location: Seattle, WA (-122.3321, 47.6062)
    SELECT TO_GEOGRAPHY('POINT(-122.3321 47.6062)') AS "g"
)
SELECT
    z."zipcode_geom"                      AS "polygon",
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county",
    COALESCE(p."total_population", 0)     AS "total_population"
FROM     ZIP_AREAS   z
CROSS JOIN CENTER_POINT c
LEFT  JOIN POP_2010  p
       ON p."zipcode" = z."zipcode"
WHERE ST_DISTANCE( TO_GEOGRAPHY(z."zipcode_geom"), c."g") <= 10000   -- 10 km
;