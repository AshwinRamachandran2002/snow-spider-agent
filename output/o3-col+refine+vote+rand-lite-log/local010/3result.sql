WITH c AS (
    SELECT
        ad."airport_code",
        CAST(SUBSTR(ad."coordinates", 2,
                    INSTR(ad."coordinates", ',') - 2) AS REAL) AS lon,
        CAST(SUBSTR(ad."coordinates",
                    INSTR(ad."coordinates", ',') + 1,
                    INSTR(ad."coordinates", ')') -
                    INSTR(ad."coordinates", ',') - 1) AS REAL) AS lat,
        json_extract(ad."city", '$.en') AS city_en
    FROM "airports_data" AS ad
),
d AS (
    SELECT
        dep.city_en AS dep_city,
        arr.city_en AS arr_city,
        6371 *
        ACOS(
            COS(RADIANS(dep.lat)) * COS(RADIANS(arr.lat)) *
            COS(RADIANS(arr.lon) - RADIANS(dep.lon)) +
            SIN(RADIANS(dep.lat)) * SIN(RADIANS(arr.lat))
        ) AS km
    FROM "flights" AS f
    JOIN c AS dep ON dep."airport_code" = f."departure_airport"
    JOIN c AS arr ON arr."airport_code" = f."arrival_airport"
),
pairs AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city2,
        km
    FROM d
),
avg_pair AS (
    SELECT
        city1,
        city2,
        AVG(km) AS avg_km
    FROM pairs
    GROUP BY city1, city2
),
bucketed AS (
    SELECT
        city1,
        city2,
        avg_km,
        CASE
            WHEN avg_km < 1000 THEN '0-999'
            WHEN avg_km < 2000 THEN '1000-1999'
            WHEN avg_km < 3000 THEN '2000-2999'
            WHEN avg_km < 4000 THEN '3000-3999'
            WHEN avg_km < 5000 THEN '4000-4999'
            WHEN avg_km < 6000 THEN '5000-5999'
            ELSE '6000+'
        END AS dist_range
    FROM avg_pair
),
counts AS (
    SELECT
        dist_range,
        COUNT(*) AS pair_cnt
    FROM bucketed
    GROUP BY dist_range
)
SELECT
    MIN(pair_cnt) AS fewest_pairs
FROM counts;