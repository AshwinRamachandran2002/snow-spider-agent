WITH abakan_point AS (
    SELECT
        ST_MakePoint(
            TO_DOUBLE(SPLIT(REPLACE(REPLACE("coordinates", '(', ''), ')', ''), ',')[0]),
            TO_DOUBLE(SPLIT(REPLACE(REPLACE("coordinates", '(', ''), ')', ''), ',')[1])
        ) AS "abakan_point"
    FROM AIRLINES.AIRLINES."AIRPORTS_DATA"
    WHERE "airport_code" = 'ABA'
),
connected_airports AS (
    SELECT DISTINCT
        CASE 
            WHEN "departure_airport" = 'ABA' THEN "arrival_airport" 
            ELSE "departure_airport" 
        END AS "connected_airport"
    FROM AIRLINES.AIRLINES."FLIGHTS"
    WHERE "departure_airport" = 'ABA' OR "arrival_airport" = 'ABA'
),
airport_coordinates AS (
    SELECT
        a."airport_code",
        (PARSE_JSON(a."city"):"en")::STRING AS "city",
        ST_MakePoint(
            TO_DOUBLE(SPLIT(REPLACE(REPLACE(a."coordinates", '(', ''), ')', ''), ',')[0]),
            TO_DOUBLE(SPLIT(REPLACE(REPLACE(a."coordinates", '(', ''), ')', ''), ',')[1])
        ) AS "geog_point"
    FROM AIRLINES.AIRLINES."AIRPORTS_DATA" a
    WHERE a."airport_code" IN (SELECT "connected_airport" FROM connected_airports)
),
distance_calculations AS (
    SELECT
        ac."city",
        ST_Distance((SELECT "abakan_point" FROM abakan_point), ac."geog_point") / 1000 AS "Distance_km"
    FROM airport_coordinates ac
)
SELECT
    "city" AS "City",
    ROUND("Distance_km", 4) AS "Distance_km"
FROM distance_calculations
ORDER BY "Distance_km" DESC NULLS LAST
LIMIT 1;