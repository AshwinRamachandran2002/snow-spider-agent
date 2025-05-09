WITH "AIRPORT_PARSED" AS (
    SELECT
        "airport_code",
        TRY_TO_DECIMAL(
            SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''),',',1)
        ) AS "lon",
        TRY_TO_DECIMAL(
            SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''),',',2)
        ) AS "lat",
        TRIM(PARSE_JSON("city"):"en"::STRING) AS "city_en"
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
"ABAKAN_FLIGHTS" AS (
    SELECT
        f."flight_id",
        dep."lon"  AS "dep_lon",
        dep."lat"  AS "dep_lat",
        arr."lon"  AS "arr_lon",
        arr."lat"  AS "arr_lat"
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN "AIRPORT_PARSED" dep
         ON f."departure_airport" = dep."airport_code"
    JOIN "AIRPORT_PARSED" arr
         ON f."arrival_airport"   = arr."airport_code"
    WHERE dep."city_en" = 'Abakan'
       OR arr."city_en" = 'Abakan'
),
"DISTANCE_CALC" AS (
    SELECT
        "flight_id",
        2 * 6371 *
        ASIN(
            SQRT(
                POWER(SIN((RADIANS("arr_lat") - RADIANS("dep_lat")) / 2), 2) +
                COS(RADIANS("dep_lat")) * COS(RADIANS("arr_lat")) *
                POWER(SIN((RADIANS("arr_lon") - RADIANS("dep_lon")) / 2), 2)
            )
        ) AS "distance_km"
    FROM "ABAKAN_FLIGHTS"
)
SELECT
    MAX("distance_km") AS "longest_distance_km"
FROM "DISTANCE_CALC";