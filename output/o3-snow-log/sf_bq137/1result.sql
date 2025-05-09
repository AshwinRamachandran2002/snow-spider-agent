WITH reference_pt AS (   -- Seattle, WA  (longitude , latitude)
    SELECT ST_POINT(-122.3321 , 47.6062) AS geom          -- GEOGRAPHY
),

/* ZIP Code polygons whose centroids are within 10 km of the reference point */
zcta_near AS (           
    SELECT
        z.*,
        ST_GEOGFROMTEXT(z."zipcode_geom")               AS geom_zip
    FROM CENSUS_BUREAU_USA.UTILITY_US."ZIPCODE_AREA" z,
         reference_pt p
    WHERE ST_DISTANCE( ST_GEOGFROMTEXT(z."zipcode_geom"), p.geom ) <= 10000   -- 10 000 m
),

/* 2010 population totals: male + female, all-ages (rows where min/max age are NULL) */
pop2010 AS (
    SELECT
        LPAD("zipcode", 5, '0')            AS zipcode,
        SUM("population")                  AS total_population
    FROM   CENSUS_BUREAU_USA.CENSUS_BUREAU_USA."POPULATION_BY_ZIP_2010"
    WHERE  "gender" IN ('male','female')
      AND  "minimum_age" IS NULL
      AND  "maximum_age" IS NULL
    GROUP BY LPAD("zipcode", 5, '0')
)

/* Final result */
SELECT
    z."zipcode_geom"          AS zipcode_polygon,
    z."area_land_meters",
    z."area_water_meters",
    z."latitude",
    z."longitude",
    z."state_code",
    z."state_name",
    z."city",
    z."county",
    COALESCE(p.total_population, 0) AS total_population
FROM   zcta_near z
LEFT  JOIN pop2010 p
       ON p.zipcode = LPAD(z."zipcode", 5, '0');