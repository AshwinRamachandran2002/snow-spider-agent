WITH abakan_airports AS (
    SELECT "airport_code"
    FROM   "airports_data"
    WHERE  json_extract("city", '$.en') = 'Abakan'
       OR  json_extract("city", '$.ru') = 'Абакан'
),
abakan_flights AS (
    SELECT  dep."coordinates" AS dep_coord,
            arr."coordinates" AS arr_coord
    FROM    "flights"        AS f
    JOIN    "airports_data"  AS dep ON dep."airport_code" = f."departure_airport"
    JOIN    "airports_data"  AS arr ON arr."airport_code" = f."arrival_airport"
    WHERE   f."departure_airport" IN (SELECT "airport_code" FROM abakan_airports)
        OR  f."arrival_airport"   IN (SELECT "airport_code" FROM abakan_airports)
),
coords AS (
    SELECT
        /* split "(lon,lat)" strings into numeric degrees */
        CAST(substr(dep_coord, 2,
                    instr(dep_coord, ',') - 2) AS REAL)                           AS dep_lon_deg,
        CAST(substr(dep_coord,
                    instr(dep_coord, ',') + 1,
                    length(dep_coord) - instr(dep_coord, ',') - 1) AS REAL)       AS dep_lat_deg,
        CAST(substr(arr_coord, 2,
                    instr(arr_coord, ',') - 2) AS REAL)                           AS arr_lon_deg,
        CAST(substr(arr_coord,
                    instr(arr_coord, ',') + 1,
                    length(arr_coord) - instr(arr_coord, ',') - 1) AS REAL)       AS arr_lat_deg
    FROM   abakan_flights
),
distances AS (
    SELECT
        6371 * acos(
              cos(dep_lat_deg * 0.017453292519943) *
              cos(arr_lat_deg * 0.017453292519943) *
              cos(arr_lon_deg * 0.017453292519943 - dep_lon_deg * 0.017453292519943)
            + sin(dep_lat_deg * 0.017453292519943) *
              sin(arr_lat_deg * 0.017453292519943)
        ) AS distance_km
    FROM   coords
)
SELECT ROUND(MAX(distance_km), 4) AS longest_abakan_route_km
FROM   distances;