WITH "AIRPORTS" AS (
    SELECT
        "airport_code",
        PARSE_JSON("city"):"en"::string             AS "city_en",
        TRIM(SPLIT_PART(REGEXP_REPLACE("coordinates",'[()]',''),',',2))::float AS "lat_deg",
        TRIM(SPLIT_PART(REGEXP_REPLACE("coordinates",'[()]',''),',',1))::float AS "lon_deg"
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
"ABAKAN_FLIGHTS" AS (
    SELECT
        f."flight_id",
        dep."lat_deg"  AS "lat1",
        dep."lon_deg"  AS "lon1",
        arr."lat_deg"  AS "lat2",
        arr."lon_deg"  AS "lon2"
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN "AIRPORTS" dep ON f."departure_airport" = dep."airport_code"
    JOIN "AIRPORTS" arr ON f."arrival_airport"   = arr."airport_code"
    WHERE dep."city_en" = 'Abakan' OR arr."city_en" = 'Abakan'
),
"DISTANCES" AS (
    SELECT
        "flight_id",
        2 * 6371 * ASIN(SQRT(
              POWER(SIN((RADIANS("lat2") - RADIANS("lat1")) / 2), 2)
            + COS(RADIANS("lat1")) * COS(RADIANS("lat2"))
            * POWER(SIN((RADIANS("lon2") - RADIANS("lon1")) / 2), 2)
        )) AS "distance_km"
    FROM "ABAKAN_FLIGHTS"
)
SELECT MAX("distance_km") AS "longest_route_km"
FROM "DISTANCES";