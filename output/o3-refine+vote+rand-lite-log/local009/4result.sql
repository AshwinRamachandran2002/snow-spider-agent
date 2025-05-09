WITH RECURSIVE
--------------------------------------------------------------------
-- 1.  Abakan airport codes
--------------------------------------------------------------------
abakan_airports AS (
    SELECT airport_code
    FROM airports_data
    WHERE lower(json_extract(city,'$.en')) = 'abakan'
),
--------------------------------------------------------------------
-- 2.  Longitude / latitude of every airport (degrees)
--------------------------------------------------------------------
airport_coords AS (
    SELECT
        airport_code,
        CAST(substr(coordinates, 2,
                    instr(coordinates, ',') - 2) AS REAL)               AS lon,
        CAST(replace(substr(coordinates,
                            instr(coordinates, ',') + 1), ')','') AS REAL) AS lat
    FROM airports_data
),
--------------------------------------------------------------------
-- 3.  All flights whose origin or destination is Abakan
--------------------------------------------------------------------
routes AS (
    SELECT
        dep.lon AS lon1, dep.lat AS lat1,
        arr.lon AS lon2, arr.lat AS lat2
    FROM flights f
    JOIN airport_coords dep ON dep.airport_code = f.departure_airport
    JOIN airport_coords arr ON arr.airport_code = f.arrival_airport
    WHERE f.departure_airport IN (SELECT airport_code FROM abakan_airports)
       OR f.arrival_airport   IN (SELECT airport_code FROM abakan_airports)
),
--------------------------------------------------------------------
-- 4.  Planar‑projection distance² (km²) for every route
--     (uses small‑angle approximation, avoids trig functions)
--------------------------------------------------------------------
distances_sq AS (
    SELECT
        /* constants */
        111.321                                                    AS km_per_lon,
        110.574                                                    AS km_per_lat,
        0.017453292519943295                                       AS rad,
        /* deltas in degrees */
        (lon2 - lon1)                                              AS dlon_deg,
        (lat2 - lat1)                                              AS dlat_deg,
        ((lat1 + lat2) / 2.0)                                      AS avg_lat_deg
    FROM routes
),
distances_calc AS (
    SELECT
        /* convert average latitude to radians */
        avg_lat_deg * rad                                          AS avg_lat_rad,
        dlon_deg,
        dlat_deg,
        km_per_lon,
        km_per_lat
    FROM distances_sq
),
distances_km2 AS (
    SELECT
        /* cos(average latitude) approximated with a 6th‑order
           Taylor series : 1 - x²/2 + x⁴/24 - x⁶/720               */
        (1
         - (avg_lat_rad * avg_lat_rad) / 2.0
         + (avg_lat_rad*avg_lat_rad*avg_lat_rad*avg_lat_rad) / 24.0
         - (avg_lat_rad*avg_lat_rad*avg_lat_rad*avg_lat_rad
            *avg_lat_rad*avg_lat_rad) / 720.0)                    AS cos_lat,
        dlon_deg,
        dlat_deg,
        km_per_lon,
        km_per_lat
    FROM distances_calc
),
dist_sq AS (
    SELECT
        /* convert degree deltas to kilometres */
        (dlon_deg * km_per_lon * cos_lat)  AS dx,
        (dlat_deg * km_per_lat)            AS dy
    FROM distances_km2
),
all_sq AS (
    SELECT (dx*dx + dy*dy) AS d2 FROM dist_sq
),
--------------------------------------------------------------------
-- 5.  Largest distance²
--------------------------------------------------------------------
max_d2 AS (
    SELECT MAX(d2) AS d2 FROM all_sq
),
--------------------------------------------------------------------
-- 6.  Square‑root via Newton iterations (no sqrt() function)
--------------------------------------------------------------------
sqrt_iter AS (
    -- initial guess
    SELECT d2,
           d2/2.0                         AS g,
           0                              AS iter
    FROM max_d2
    UNION ALL
    SELECT d2,
           0.5*(g + d2/g)                 AS g,
           iter+1
    FROM sqrt_iter
    WHERE iter < 30       -- 30 iterations give high accuracy
),
sqrt_final AS (
    SELECT g AS longest_distance_km
    FROM sqrt_iter
    ORDER BY iter DESC
    LIMIT 1
)
--------------------------------------------------------------------
-- 7.  Answer
--------------------------------------------------------------------
SELECT longest_distance_km
FROM sqrt_final;