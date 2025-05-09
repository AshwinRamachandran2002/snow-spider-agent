WITH point AS (
    /* Reference location:  (-122.3321 47.6062)  =  Seattle, WA */
    SELECT TO_GEOGRAPHY('POINT(-122.3321 47.6062)') AS "geom"
),

/* 2010 Census – sum of male + female totals (no age constraints)               */
pop_2010 AS (
    SELECT
        "zipcode",
        SUM("population") AS "total_population"
    FROM CENSUS_BUREAU_USA.CENSUS_BUREAU_USA.POPULATION_BY_ZIP_2010
    WHERE "minimum_age" IS NULL
      AND "maximum_age" IS NULL
      AND LOWER(COALESCE("gender", '')) IN ('male','female')
    GROUP BY "zipcode"
)

SELECT
    z."zipcode_geom"        AS "polygon",
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county",
    p."total_population"
FROM CENSUS_BUREAU_USA.UTILITY_US.ZIPCODE_AREA            AS z
JOIN pop_2010                                              AS p  ON z."zipcode" = p."zipcode"
CROSS JOIN point
WHERE ST_DISTANCE(
          TO_GEOGRAPHY(z."zipcode_geom"),
          point."geom"
      ) <= 10000           -- 10 km radius (10,000 meters)
;