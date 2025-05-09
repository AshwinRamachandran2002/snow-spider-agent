WITH "AP" AS (   /* airports with parsed coordinates and city name */
    SELECT
        "airport_code",
        CAST(SPLIT_PART(REGEXP_REPLACE("coordinates",'[()]',''),',',1) AS FLOAT) AS lon_deg,
        CAST(SPLIT_PART(REGEXP_REPLACE("coordinates",'[()]',''),',',2) AS FLOAT) AS lat_deg,
        LOWER(TRIM(PARSE_JSON("city"):en::STRING))                       AS city_name
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),  /* flights where Abakan is either origin or destination */
"ABAKAN_FLIGHTS" AS (
    SELECT
        f."flight_id",
        f."departure_airport",
        f."arrival_airport"
    FROM AIRLINES.AIRLINES.FLIGHTS  f
    JOIN "AP" dep ON dep."airport_code" = f."departure_airport"
    JOIN "AP" arr ON arr."airport_code" = f."arrival_airport"
    WHERE dep.city_name = 'abakan' OR arr.city_name = 'abakan'
),  /* attach coordinates to every Abakan-related flight */
"FLIGHT_COORDS" AS (
    SELECT
        af."flight_id",
        dep.lon_deg  AS dep_lon,
        dep.lat_deg  AS dep_lat,
        arr.lon_deg  AS arr_lon,
        arr.lat_deg  AS arr_lat
    FROM "ABAKAN_FLIGHTS" af
    JOIN "AP" dep ON dep."airport_code" = af."departure_airport"
    JOIN "AP" arr ON arr."airport_code" = af."arrival_airport"
),  /* Haversine distance for each such flight */
"DISTANCES" AS (
    SELECT
        "flight_id",
        2 * 6371 * ASIN(
            SQRT(
                POWER(SIN((RADIANS(arr_lat) - RADIANS(dep_lat)) / 2), 2) +
                COS(RADIANS(dep_lat)) * COS(RADIANS(arr_lat)) *
                POWER(SIN((RADIANS(arr_lon) - RADIANS(dep_lon)) / 2), 2)
            )
        ) AS distance_km
    FROM "FLIGHT_COORDS"
)
SELECT
    MAX(distance_km) AS longest_route_distance_km
FROM "DISTANCES";