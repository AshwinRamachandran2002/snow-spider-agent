WITH "AIRPORTS" AS (   -- get city names and numeric coordinates for every airport
    SELECT
        "airport_code",
        TRY_PARSE_JSON("city"):"en"::string                                                    AS "city_en",
        SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''),',',2)::DOUBLE                AS "lat_deg",
        SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''),',',1)::DOUBLE                AS "lon_deg"
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
"FLIGHTS_COORDS" AS (  -- attach coordinates of both airports to every flight
    SELECT
        f."flight_id",
        dep."city_en"                                            AS "dep_city",
        arr."city_en"                                            AS "arr_city",
        dep."lat_deg"                                            AS "dep_lat",
        dep."lon_deg"                                            AS "dep_lon",
        arr."lat_deg"                                            AS "arr_lat",
        arr."lon_deg"                                            AS "arr_lon"
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN "AIRPORTS" dep ON dep."airport_code" = f."departure_airport"
    JOIN "AIRPORTS" arr ON arr."airport_code" = f."arrival_airport"
    WHERE dep."city_en" IS NOT NULL AND arr."city_en" IS NOT NULL
),
"DISTANCES" AS (        -- haversine distance for every individual flight
    SELECT
        "dep_city",
        "arr_city",
        6371 * 2 * ASIN(
                 SQRT(
                       POWER(SIN((RADIANS("arr_lat") - RADIANS("dep_lat")) / 2), 2)
                     + COS(RADIANS("dep_lat")) * COS(RADIANS("arr_lat"))
                     * POWER(SIN((RADIANS("arr_lon") - RADIANS("dep_lon")) / 2), 2)
                 )
        )                                                    AS "distance_km"
    FROM "FLIGHTS_COORDS"
),
"ROUTES" AS (           -- make the route direction–independent
    SELECT
        CASE WHEN "dep_city" < "arr_city" THEN "dep_city" ELSE "arr_city" END  AS "city1",
        CASE WHEN "dep_city" < "arr_city" THEN "arr_city" ELSE "dep_city" END  AS "city2",
        "distance_km"
    FROM "DISTANCES"
),
"AVG_ROUTES" AS (       -- average distance for each unique city pair
    SELECT
        "city1",
        "city2",
        AVG("distance_km")                                   AS "avg_distance"
    FROM "ROUTES"
    GROUP BY "city1", "city2"
),
"BINNED" AS (           -- place every pair in the required distance bucket
    SELECT
        "city1",
        "city2",
        "avg_distance",
        CASE
            WHEN "avg_distance" < 1000 THEN '0-999'
            WHEN "avg_distance" < 2000 THEN '1000-1999'
            WHEN "avg_distance" < 3000 THEN '2000-2999'
            WHEN "avg_distance" < 4000 THEN '3000-3999'
            WHEN "avg_distance" < 5000 THEN '4000-4999'
            WHEN "avg_distance" < 6000 THEN '5000-5999'
            ELSE '6000+'
        END                                                 AS "distance_range"
    FROM "AVG_ROUTES"
),
"COUNTS" AS (           -- count pairs in every distance bucket
    SELECT
        "distance_range",
        COUNT(*)                                            AS "pairs_count"
    FROM "BINNED"
    GROUP BY "distance_range"
)
-- the answer: smallest number of unique city pairs in any bucket
SELECT MIN("pairs_count") AS "fewest_unique_city_pairs"
FROM "COUNTS";