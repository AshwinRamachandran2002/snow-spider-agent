WITH airport_coords AS (        -- longitude / latitude per airport + city name
    SELECT
        airport_code,
        json_extract(city,'$.en')                                    AS city_en,
        CAST(SUBSTR(coordinates, 2, instr(coordinates, ',')-2) AS REAL)                AS lon,
        CAST(SUBSTR(coordinates, instr(coordinates, ',')+1,
                    length(coordinates)-instr(coordinates, ',')-1) AS REAL)            AS lat
    FROM airports_data
),
route_dist AS (                 -- distance for every individual flight
    SELECT
        CASE WHEN dep.city_en < arr.city_en THEN dep.city_en ELSE arr.city_en END AS city_a,
        CASE WHEN dep.city_en < arr.city_en THEN arr.city_en ELSE dep.city_en END AS city_b,
        ROUND(
            6371 * 2 * ASIN(
                SQRT(
                    POWER(SIN((radians(arr.lat) - radians(dep.lat)) / 2), 2) +
                    COS(radians(dep.lat)) * COS(radians(arr.lat)) *
                    POWER(SIN((radians(arr.lon) - radians(dep.lon)) / 2), 2)
                )
            ), 0
        ) AS dist_km
    FROM flights AS f
    JOIN airport_coords AS dep ON dep.airport_code = f.departure_airport
    JOIN airport_coords AS arr ON arr.airport_code = f.arrival_airport
),
city_pairs AS (                 -- average distance for each unordered city-pair
    SELECT city_a,
           city_b,
           AVG(dist_km) AS avg_dist
    FROM   route_dist
    GROUP  BY city_a, city_b
),
bucket_counts AS (              -- number of pairs in every distance bucket
    SELECT CASE
             WHEN avg_dist < 1000 THEN '0-999'
             WHEN avg_dist < 2000 THEN '1000-1999'
             WHEN avg_dist < 3000 THEN '2000-2999'
             WHEN avg_dist < 4000 THEN '3000-3999'
             WHEN avg_dist < 5000 THEN '4000-4999'
             WHEN avg_dist < 6000 THEN '5000-5999'
             ELSE                     '6000+'
           END                AS dist_bucket,
           COUNT(*)           AS pair_cnt
    FROM   city_pairs
    GROUP  BY dist_bucket
)
SELECT MIN(pair_cnt) AS fewest_pairs_across_buckets
FROM   bucket_counts;