WITH "AIRPORTS" AS (
    SELECT
        "airport_code",
        /* longitude and latitude in decimal degrees */
        TO_DOUBLE(SPLIT(REGEXP_REPLACE("coordinates",'[()]',''),',')[0]) AS "lon_deg",
        TO_DOUBLE(SPLIT(REGEXP_REPLACE("coordinates",'[()]',''),',')[1]) AS "lat_deg",
        /* English city name in lower-case */
        LOWER(GET(PARSE_JSON("city"),'en')::string)                AS "city_en"
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
"FLIGHTS_ABAKAN" AS (
    /* flights where Abakan is either the origin or the destination */
    SELECT
        f."flight_id",
        f."departure_airport",
        f."arrival_airport"
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN "AIRPORTS" d ON f."departure_airport" = d."airport_code"
    JOIN "AIRPORTS" a ON f."arrival_airport" = a."airport_code"
    WHERE d."city_en" = 'abakan'
       OR a."city_en" = 'abakan'
),
"DISTANCES" AS (
    /* great-circle (Haversine) distance for each selected flight */
    SELECT
        fa."flight_id",
        2 * 6371 *                                     -- Earth radius in km
        ASIN(
            SQRT(
                POWER(SIN((RADIANS(a."lat_deg") - RADIANS(d."lat_deg"))/2),2) +
                COS(RADIANS(d."lat_deg")) * COS(RADIANS(a."lat_deg")) *
                POWER(SIN((RADIANS(a."lon_deg") - RADIANS(d."lon_deg"))/2),2)
            )
        )                                               AS "distance_km"
    FROM "FLIGHTS_ABAKAN" fa
    JOIN "AIRPORTS" d ON fa."departure_airport" = d."airport_code"
    JOIN "AIRPORTS" a ON fa."arrival_airport" = a."airport_code"
)
SELECT MAX("distance_km") AS "longest_route_distance_km"
FROM "DISTANCES";