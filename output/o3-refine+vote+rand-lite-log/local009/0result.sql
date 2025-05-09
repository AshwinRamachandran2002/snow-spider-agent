WITH abakan_airports AS (
    /* IATA of Abakan */
    SELECT airport_code
    FROM airports_data
    WHERE lower(json_extract(city,'$.en')) = 'abakan'
),
coords AS (
    /* split POINT '(lon,lat)' into numeric columns */
    SELECT
        airport_code,
        CAST(substr(coordinates, 2,
                    instr(coordinates, ',') - 2) AS REAL)             AS lon,
        CAST(substr(coordinates,
                    instr(coordinates, ',') + 1,
                    instr(coordinates, ')') - instr(coordinates, ',') - 1) AS REAL) AS lat
    FROM airports_data
),
routes AS (
    /* every flight where Abakan is origin or destination */
    SELECT departure_airport AS dep,
           arrival_airport   AS arr
    FROM flights
    WHERE departure_airport IN (SELECT airport_code FROM abakan_airports)
       OR arrival_airport   IN (SELECT airport_code FROM abakan_airports)
),
distance_sq AS (
    /* planar‑projection distance squared (km²) */
    SELECT
        dep,
        arr,
        ((c2.lon - c1.lon) * 111.32) * ((c2.lon - c1.lon) * 111.32) +
        ((c2.lat - c1.lat) * 111.32) * ((c2.lat - c1.lat) * 111.32) AS s
    FROM routes
    JOIN coords c1 ON c1.airport_code = dep
    JOIN coords c2 ON c2.airport_code = arr
),
/* Newton–Raphson square‑root : 20 iterations are enough for km‑precision */
sqrt_iter(dep, arr, iter, x, s) AS (
    SELECT dep, arr, 0, s/2.0, s FROM distance_sq
    UNION ALL
    SELECT dep,
           arr,
           iter + 1,
           (x + s/x) / 2.0,
           s
    FROM sqrt_iter
    WHERE iter < 20
),
distances AS (
    SELECT dep, arr, x AS distance_km
    FROM sqrt_iter
    WHERE iter = 20           -- last iteration is the √
)
SELECT MAX(distance_km) AS longest_route_km
FROM distances;