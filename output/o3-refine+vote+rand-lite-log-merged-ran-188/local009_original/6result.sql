WITH
/* 1.  Abakan airport code(s) */
abakan_airports AS (
    SELECT airport_code
    FROM airports_data
    WHERE lower(json_extract(city,'$.en')) = 'abakan'
       OR lower(json_extract(airport_name,'$.en')) LIKE '%abakan%'
),

/* 2.  Every unique route that starts or ends in Abakan               */
routes AS (
    SELECT DISTINCT departure_airport,
           arrival_airport
    FROM flights
    WHERE departure_airport IN (SELECT airport_code FROM abakan_airports)
       OR arrival_airport   IN (SELECT airport_code FROM abakan_airports)
),

/* 3.  Retrieve coordinates of both ends of each route                */
coords AS (
    SELECT r.departure_airport,
           r.arrival_airport,
           d.coordinates AS dep_coord,
           a.coordinates AS arr_coord
    FROM routes r
    JOIN airports_data d ON d.airport_code = r.departure_airport
    JOIN airports_data a ON a.airport_code = r.arrival_airport
),

/* 4.  Parse “(lon,lat)” text into separate numeric columns           */
parsed AS (
    SELECT 
        departure_airport,
        arrival_airport,
        /* longitude of departure */
        CAST(
             SUBSTR(dep_coord, 2, INSTR(dep_coord, ',')-2)
             AS REAL
        ) AS dep_lon,
        /* latitude  of departure */
        CAST(
             REPLACE(
                     SUBSTR(dep_coord,
                            INSTR(dep_coord, ',')+1,
                            LENGTH(dep_coord)-INSTR(dep_coord, ',')-1),
                     ')',''
             ) AS REAL
        ) AS dep_lat,
        /* longitude of arrival */
        CAST(
             SUBSTR(arr_coord, 2, INSTR(arr_coord, ',')-2)
             AS REAL
        ) AS arr_lon,
        /* latitude  of arrival */
        CAST(
             REPLACE(
                     SUBSTR(arr_coord,
                            INSTR(arr_coord, ',')+1,
                            LENGTH(arr_coord)-INSTR(arr_coord, ',')-1),
                     ')',''
             ) AS REAL
        ) AS arr_lat
    FROM coords
),

/* 5.  Differences and average latitude (all still in degrees)        */
diffs AS (
    SELECT 
        departure_airport,
        arrival_airport,
        (dep_lat - arr_lat)                         AS dlat,
        (dep_lon - arr_lon)                         AS dlon,
        (dep_lat + arr_lat)/2.0                     AS lat_avg
    FROM parsed
),

/* 6.  Build cos(lat_avg) via an 8‑term Maclaurin series              */
series AS (
    SELECT
        departure_airport,
        arrival_airport,
        dlat,
        dlon,
        /* radian value and its even powers */
        (lat_avg * 3.141592653589793 / 180.0)            AS t,
        (lat_avg * 3.141592653589793 / 180.0)
        * (lat_avg * 3.141592653589793 / 180.0)          AS t2
    FROM diffs
),
cosine AS (
    SELECT
        departure_airport,
        arrival_airport,
        dlat,
        dlon,
        /*  powers of t   */
        t2                                                AS r2,
        t2*t2                                             AS r4,
        t2*t2*t2                                          AS r6,
        (t2*t2)*(t2*t2)                                   AS r8
    FROM series
),
cos_val AS (
    SELECT
        departure_airport,
        arrival_airport,
        dlat,
        dlon,
        /* cos(lat_avg) ≈ 1 − r2/2! + r4/4! − r6/6! + r8/8!           */
        1 - r2/2.0 + r4/24.0 - r6/720.0 + r8/40320.0      AS cos_lat_avg
    FROM cosine
),

/* 7.  Distance‑squared using equirectangular approximation            */
dist_sq AS (
    SELECT
        departure_airport,
        arrival_airport,
        /* 111.195 km per degree of latitude                           */
        12364.328025 *                           -- 111.195^2  (km² per degree²)
        ( dlat*dlat + (dlon*cos_lat_avg)*(dlon*cos_lat_avg) )  AS dist_sq_km2
    FROM cos_val
),

/* 8.  Recursive Newton‑Raphson to obtain sqrt(dist_sq_km2)            */
sqrt_iter(departure_airport, arrival_airport, dist_sq_km2, guess, step) AS (
       /* anchor: initial guess = dist_sq / 2                         */
       SELECT departure_airport,
              arrival_airport,
              dist_sq_km2,
              dist_sq_km2/2.0       AS guess,
              0                     AS step
       FROM dist_sq
    UNION ALL
       SELECT departure_airport,
              arrival_airport,
              dist_sq_km2,
              (guess + dist_sq_km2/guess)/2.0,
              step + 1
       FROM sqrt_iter
       WHERE step < 10              -- 10 iterations are enough
),

/* 9.  Grab the 10th (final) iteration                                 */
distances AS (
    SELECT departure_airport,
           arrival_airport,
           guess AS distance_km
    FROM sqrt_iter
    WHERE step = 10
)

SELECT MAX(distance_km) AS longest_route_distance_km
FROM distances;