WITH coords AS (          -- longitude / latitude for every airport
    SELECT
        airport_code,
        json_extract(city,'$.en')                                   AS city,
        CAST(substr(coordinates, 2, instr(coordinates, ',')-2)  AS REAL) AS lon,
        CAST(substr(coordinates, instr(coordinates, ',')+1,
                    length(coordinates)-instr(coordinates, ',')-1) AS REAL) AS lat
    FROM airports_data
),
legs AS (                  -- every distinct airport‑to‑airport leg
    SELECT DISTINCT
        departure_airport AS dep_ap,
        arrival_airport   AS arr_ap
    FROM flights
),
distances AS (             -- proxy distance for each leg + unordered city pair
    SELECT
        111.0 * (ABS(c2.lat - c1.lat) + ABS(c2.lon - c1.lon))       AS distance_km,
        CASE WHEN c1.city < c2.city THEN c1.city ELSE c2.city END   AS city_a,
        CASE WHEN c1.city < c2.city THEN c2.city ELSE c1.city END   AS city_b
    FROM legs
    JOIN coords AS c1 ON c1.airport_code = dep_ap
    JOIN coords AS c2 ON c2.airport_code = arr_ap
),
city_pairs AS (            -- average distance over all legs between the two cities
    SELECT
        city_a,
        city_b,
        AVG(distance_km) AS avg_distance
    FROM distances
    GROUP BY city_a, city_b
),
bucketed AS (              -- put every pair into the required distance ranges
    SELECT
        CASE
            WHEN avg_distance < 1000 THEN '0'
            WHEN avg_distance < 2000 THEN '1000'
            WHEN avg_distance < 3000 THEN '2000'
            WHEN avg_distance < 4000 THEN '3000'
            WHEN avg_distance < 5000 THEN '4000'
            WHEN avg_distance < 6000 THEN '5000'
            ELSE '6000+'
        END AS range_label,
        COUNT(*) AS pair_cnt
    FROM city_pairs
    GROUP BY range_label
)
SELECT MIN(pair_cnt) AS pairs_in_least_populated_range
FROM bucketed;