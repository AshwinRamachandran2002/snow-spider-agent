WITH
/* 1. Abakan airport code(s) */
abakan_airports AS (
    SELECT airport_code
    FROM airports_data
    WHERE LOWER(json_extract(city,'$.en')) = 'abakan'
),

/* 2. Numeric longitude / latitude for every airport */
coords AS (
    SELECT
        airport_code,
        CAST(
            substr(
                REPLACE(REPLACE(coordinates,'(',''),')',''),
                1,
                instr(REPLACE(REPLACE(coordinates,'(',''),')',''),',')-1
            ) AS REAL
        ) AS lon,
        CAST(
            substr(
                REPLACE(REPLACE(coordinates,'(',''),')',''),
                instr(REPLACE(REPLACE(coordinates,'(',''),')',''),',')+1
            ) AS REAL
        ) AS lat
    FROM airports_data
),

/* 3. Routes where Abakan is origin or destination */
routes AS (
    SELECT DISTINCT
           f.departure_airport AS dep_code,
           f.arrival_airport   AS arr_code
    FROM flights AS f
    WHERE f.departure_airport IN (SELECT airport_code FROM abakan_airports)
       OR f.arrival_airport   IN (SELECT airport_code FROM abakan_airports)
),

/* 4. Squared planar distance (degrees²) for each such route */
dist2 AS (
    SELECT
        (dep.lat - arr.lat)*(dep.lat - arr.lat) +
        (dep.lon - arr.lon)*(dep.lon - arr.lon) AS d2
    FROM routes
    JOIN coords AS dep ON dep.airport_code = routes.dep_code
    JOIN coords AS arr ON arr.airport_code = routes.arr_code
),

/* 5. Maximum squared distance */
max_dist2 AS (
    SELECT MAX(d2) AS d2
    FROM dist2
),

/* 6. Newton–Raphson iterations to obtain √(max_d2) without using sqrt() */
sqrt_iter(value, root, iter) AS (
    SELECT d2,
           CASE WHEN d2 = 0 THEN 0 ELSE d2/2.0 END AS root,
           0
    FROM max_dist2
    UNION ALL
    SELECT value,
           (root + value/root)/2.0,
           iter + 1
    FROM sqrt_iter
    WHERE iter < 25      -- 25 iterations give more than enough precision
      AND root <> 0
)

/* 7. Final answer (111.111 km per degree × √distance²) */
SELECT ROUND(111.111 * root, 4) AS longest_route_km
FROM sqrt_iter
ORDER BY iter DESC
LIMIT 1;