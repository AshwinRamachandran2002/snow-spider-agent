WITH airports AS (
    SELECT
        "airport_code",
        /* longitude (1-st element) and latitude (2-nd element) in degrees */
        TO_DOUBLE( SPLIT( REPLACE(REPLACE("coordinates",'(', ''), ')',''), ',' )[0] ) AS lon_deg,
        TO_DOUBLE( SPLIT( REPLACE(REPLACE("coordinates",'(', ''), ')',''), ',' )[1] ) AS lat_deg,
        LOWER( TRIM( parse_json("city"):en::STRING ) )                          AS city_en
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
/* all airports that belong to the city “Abakan” */
abakan_airports AS (
    SELECT "airport_code"
    FROM airports
    WHERE city_en = 'abakan'
),
/* every flight where Abakan is either the origin or the destination */
abakan_flights AS (
    SELECT
        "departure_airport",
        "arrival_airport"
    FROM AIRLINES.AIRLINES.FLIGHTS
    WHERE "departure_airport" IN (SELECT "airport_code" FROM abakan_airports)
       OR "arrival_airport"   IN (SELECT "airport_code" FROM abakan_airports)
),
/* keep unique airport-to-airport routes */
routes AS (
    SELECT DISTINCT
        "departure_airport",
        "arrival_airport"
    FROM abakan_flights
),
/* add coordinates for both airports of each route */
coords AS (
    SELECT
        r."departure_airport",
        r."arrival_airport",
        dep.lat_deg AS dep_lat,
        dep.lon_deg AS dep_lon,
        arr.lat_deg AS arr_lat,
        arr.lon_deg AS arr_lon
    FROM routes r
    JOIN airports dep ON dep."airport_code" = r."departure_airport"
    JOIN airports arr ON arr."airport_code" = r."arrival_airport"
),
/* calculate great-circle (Haversine) distance for every route */
distances AS (
    SELECT
        2 * 6371 * ASIN(
              SQRT(
                    POWER( SIN( ( RADIANS(arr_lat - dep_lat) ) / 2 ), 2 )
                  + COS( RADIANS(dep_lat) )
                  * COS( RADIANS(arr_lat) )
                  * POWER( SIN( ( RADIANS(arr_lon - dep_lon) ) / 2 ), 2 )
              )
        ) AS distance_km
    FROM coords
)
SELECT ROUND( MAX(distance_km), 4 ) AS "longest_route_km"
FROM distances;