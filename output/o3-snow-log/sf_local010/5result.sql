WITH airports AS (
    SELECT
        "airport_code",
        TRIM(SPLIT_PART(REPLACE(REPLACE("coordinates", '(', ''), ')', ''), ',', 1))::FLOAT AS lon,
        TRIM(SPLIT_PART(REPLACE(REPLACE("coordinates", '(', ''), ')', ''), ',', 2))::FLOAT AS lat,
        PARSE_JSON("city"):"en"::STRING                                                     AS city_en
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
), flights_w_coords AS (
    SELECT
        f."flight_id",
        d.city_en                                                                            AS dep_city,
        a.city_en                                                                            AS arr_city,
        d.lon                                                                                AS dep_lon,
        d.lat                                                                                AS dep_lat,
        a.lon                                                                                AS arr_lon,
        a.lat                                                                                AS arr_lat
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN airports d ON d."airport_code" = f."departure_airport"
    JOIN airports a ON a."airport_code" = f."arrival_airport"
), flight_distances AS (
    SELECT
        *,
        2 * 6371 * ASIN(
            SQRT(
                  POWER(SIN((RADIANS(arr_lat) - RADIANS(dep_lat)) / 2), 2)
                + COS(RADIANS(dep_lat)) * COS(RADIANS(arr_lat))
                  * POWER(SIN((RADIANS(arr_lon) - RADIANS(dep_lon)) / 2), 2)
            )
        ) AS distance_km
    FROM flights_w_coords
), city_pair_dist AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city2,
        distance_km
    FROM flight_distances
), avg_pair_dist AS (
    SELECT
        city1,
        city2,
        AVG(distance_km) AS avg_dist_km
    FROM city_pair_dist
    GROUP BY city1, city2
), bucketed AS (
    SELECT
        city1,
        city2,
        avg_dist_km,
        CASE
            WHEN avg_dist_km < 1000 THEN '0-1000'
            WHEN avg_dist_km < 2000 THEN '1000-2000'
            WHEN avg_dist_km < 3000 THEN '2000-3000'
            WHEN avg_dist_km < 4000 THEN '3000-4000'
            WHEN avg_dist_km < 5000 THEN '4000-5000'
            WHEN avg_dist_km < 6000 THEN '5000-6000'
            ELSE '6000+'
        END AS dist_range
    FROM avg_pair_dist
), bucket_counts AS (
    SELECT
        dist_range,
        COUNT(*) AS pairs_cnt
    FROM bucketed
    GROUP BY dist_range
)
SELECT
    MIN(pairs_cnt) AS fewest_pairs_in_any_range
FROM bucket_counts;