WITH
-- 1. airport coordinates and English city names
airports AS (
    SELECT
        airport_code,
        json_extract(city , '$.en')                              AS city,
        CAST(substr(clean, 1, instr(clean, ',') - 1)  AS REAL)  AS lon,
        CAST(substr(clean, instr(clean, ',') + 1)     AS REAL)  AS lat
    FROM (
        SELECT
            airport_code,
            city,
            REPLACE(REPLACE(coordinates,'(',''),')','') AS clean
        FROM airports_data
    )
),

-- 2. every flight with its departure / arrival city and lat‑lon
routes AS (
    SELECT
        d.city AS dep_city,
        a.city AS arr_city,
        d.lat  AS dep_lat,
        a.lat  AS arr_lat
    FROM flights  f
    JOIN airports d ON d.airport_code = f.departure_airport
    JOIN airports a ON a.airport_code = f.arrival_airport
),

-- 3. rough distance (km) : 111 km × absolute latitude difference
distances AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city_a,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city_b,
        111.0 * ABS(arr_lat - dep_lat)                              AS distance_km
    FROM routes
),

-- 4. average distance for each unordered city pair
pair_avg AS (
    SELECT city_a,
           city_b,
           AVG(distance_km) AS avg_distance
    FROM distances
    GROUP BY city_a, city_b
),

-- 5. distance buckets to be reported
ranges(label, lower, upper) AS (
    VALUES
        ('0000-0999', 0,     1000),
        ('1000-1999', 1000,  2000),
        ('2000-2999', 2000,  3000),
        ('3000-3999', 3000,  4000),
        ('4000-4999', 4000,  5000),
        ('5000-5999', 5000,  6000),
        ('6000+',     6000,  NULL)
),

-- 6. how many pairs fall into each bucket (empty buckets give 0)
bucketed AS (
    SELECT
        r.label,
        COUNT(p.city_a) AS pair_cnt
    FROM ranges r
    LEFT JOIN pair_avg p
        ON p.avg_distance >= r.lower
       AND (r.upper IS NULL OR p.avg_distance < r.upper)
    GROUP BY r.label
)

-- 7. fewest number of pairs among all distance ranges
SELECT MIN(pair_cnt) AS fewest_pairs
FROM bucketed;