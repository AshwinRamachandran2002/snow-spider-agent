WITH coords AS (
    SELECT
        airport_code,
        CAST(substr(coordinates, 2,
                    instr(coordinates, ',') - 2) AS REAL)                AS lon,
        CAST(substr(coordinates,
                    instr(coordinates, ',') + 1,
                    instr(coordinates, ')') - instr(coordinates, ',') - 1) AS REAL) AS lat,
        json_extract(city, '$.en')                                        AS city_en
    FROM airports_data
),
pairs AS (
    SELECT
        CASE WHEN c1.city_en < c2.city_en THEN c1.city_en ELSE c2.city_en END AS city1,
        CASE WHEN c1.city_en < c2.city_en THEN c2.city_en ELSE c1.city_en END AS city2,
        6371 * 2 *
        ASIN(
            SQRT(
                POW(SIN(RADIANS(c2.lat - c1.lat) / 2), 2) +
                COS(RADIANS(c1.lat)) * COS(RADIANS(c2.lat)) *
                POW(SIN(RADIANS(c2.lon - c1.lon) / 2), 2)
            )
        ) AS dist_km
    FROM flights AS f
    JOIN coords AS c1 ON c1.airport_code = f.departure_airport
    JOIN coords AS c2 ON c2.airport_code = f.arrival_airport
),
avg_pairs AS (
    SELECT
        city1,
        city2,
        AVG(dist_km) AS avg_dist
    FROM pairs
    GROUP BY city1, city2
),
bucketed AS (
    SELECT
        CASE
            WHEN avg_dist < 1000 THEN '0–999'
            WHEN avg_dist < 2000 THEN '1000–1999'
            WHEN avg_dist < 3000 THEN '2000–2999'
            WHEN avg_dist < 4000 THEN '3000–3999'
            WHEN avg_dist < 5000 THEN '4000–4999'
            WHEN avg_dist < 6000 THEN '5000–5999'
            ELSE '6000+'
        END AS distance_range
    FROM avg_pairs
),
bucket_counts AS (
    SELECT
        distance_range,
        COUNT(*) AS pair_cnt
    FROM bucketed
    GROUP BY distance_range
)
SELECT pair_cnt AS fewest_pair_count
FROM bucket_counts
WHERE pair_cnt = (SELECT MIN(pair_cnt) FROM bucket_counts);