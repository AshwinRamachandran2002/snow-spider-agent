WITH abakan AS (                       -- 1) Abakan airport code
    SELECT airport_code
    FROM   airports_data
    WHERE  lower(json_extract(city,'$.en')) LIKE '%abakan%'
), flts AS (                           -- 2) flights where Abakan is dep/arr
    SELECT flight_id,
           departure_airport,
           arrival_airport
    FROM   flights
    WHERE  departure_airport IN (SELECT airport_code FROM abakan)
       OR  arrival_airport   IN (SELECT airport_code FROM abakan)
), coords AS (                         -- 3) raw coordinates text for both ends
    SELECT f.flight_id,
           replace(replace(dep.coordinates,'(',''),')','') AS dep_c,
           replace(replace(arr.coordinates,'(',''),')','') AS arr_c
    FROM   flts AS f
    JOIN   airports_data AS dep ON dep.airport_code = f.departure_airport
    JOIN   airports_data AS arr ON arr.airport_code = f.arrival_airport
), parsed AS (                         -- 4) split lon/lat into numbers
    SELECT flight_id,
           CAST(substr(dep_c,1,instr(dep_c,',')-1) AS REAL) AS dep_lon,
           CAST(substr(dep_c,instr(dep_c,',')+1)   AS REAL) AS dep_lat,
           CAST(substr(arr_c,1,instr(arr_c,',')-1) AS REAL) AS arr_lon,
           CAST(substr(arr_c,instr(arr_c,',')+1)   AS REAL) AS arr_lat
    FROM   coords
), dist AS (                           -- 5) Haversine distance in km
    SELECT flight_id,
           6371 * acos(
               cos(dep_lat*0.017453292519943) * cos(arr_lat*0.017453292519943) *
               cos((arr_lon - dep_lon)*0.017453292519943) +
               sin(dep_lat*0.017453292519943) * sin(arr_lat*0.017453292519943)
           ) AS km
    FROM   parsed
)
SELECT ROUND(MAX(km),4) AS longest_abakan_route_km   -- 6) answer
FROM   dist;