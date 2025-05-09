WITH airports_cte AS (
    SELECT
        airport_code,
        RADIANS(
            CAST(
                SUBSTR(coordinates, 2, INSTR(coordinates, ',') - 2) AS REAL
            )
        ) AS lon,
        RADIANS(
            CAST(
                SUBSTR(
                    coordinates,
                    INSTR(coordinates, ',') + 1,
                    LENGTH(coordinates) - INSTR(coordinates, ',') - 1
                ) AS REAL
            )
        ) AS lat,
        json_extract(city, '$.en') AS city_en
    FROM airports_data
),
flight_geo AS (
    SELECT
        f.flight_id,
        dep.city_en AS dep_city,
        arr.city_en AS arr_city,
        dep.lon     AS dep_lon,
        dep.lat     AS dep_lat,
        arr.lon     AS arr_lon,
        arr.lat     AS arr_lat
    FROM flights AS f
    JOIN airports_cte AS dep ON dep.airport_code = f.departure_airport
    JOIN airports_cte AS arr ON arr.airport_code = f.arrival_airport
),
pair_dist AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city_from,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city_to,
        ROUND(
            6371 * 2 *
            ASIN(
                SQRT(
                    POWER(SIN((arr_lat - dep_lat) / 2), 2) +
                    COS(dep_lat) * COS(arr_lat) *
                    POWER(SIN((arr_lon - dep_lon) / 2), 2)
                )
            ),
            4
        ) AS distance_km
    FROM flight_geo
),
avg_pair AS (
    SELECT
        city_from,
        city_to,
        AVG(distance_km) AS avg_distance
    FROM pair_dist
    GROUP BY city_from, city_to
),
bucketed AS (
    SELECT
        CASE
            WHEN avg_distance < 1000 THEN '0-1000'
            WHEN avg_distance < 2000 THEN '1000-2000'
            WHEN avg_distance < 3000 THEN '2000-3000'
            WHEN avg_distance < 4000 THEN '3000-4000'
            WHEN avg_distance < 5000 THEN '4000-5000'
            WHEN avg_distance < 6000 THEN '5000-6000'
            ELSE                        '6000+'
        END AS dist_bucket
    FROM avg_pair
),
counts AS (
    SELECT
        dist_bucket,
        COUNT(*) AS pair_cnt
    FROM bucketed
    GROUP BY dist_bucket
)
SELECT
    MIN(pair_cnt) AS fewest_city_pairs
FROM counts;