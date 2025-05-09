WITH airport_coords AS (
    SELECT
        "airport_code",
        TO_DOUBLE(SPLIT_PART(TRANSLATE("coordinates", '()', ''), ',', 1))                AS lon,
        TO_DOUBLE(SPLIT_PART(TRANSLATE("coordinates", '()', ''), ',', 2))                AS lat,
        (PARSE_JSON("city"):"en")::string                                                AS city_en
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
), 
flight_cities AS (
    SELECT
        f."flight_id",
        dep.city_en  AS city_dep,
        dep.lon      AS lon_dep,
        dep.lat      AS lat_dep,
        arr.city_en  AS city_arr,
        arr.lon      AS lon_arr,
        arr.lat      AS lat_arr
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN airport_coords dep ON dep."airport_code" = f."departure_airport"
    JOIN airport_coords arr ON arr."airport_code" = f."arrival_airport"
), 
flight_distances AS (
    SELECT
        CASE WHEN city_dep < city_arr THEN city_dep ELSE city_arr END AS city1,
        CASE WHEN city_dep < city_arr THEN city_arr ELSE city_dep END AS city2,
        2 * 6371 *
        ASIN(
            SQRT(
                POWER(SIN((RADIANS(lat_arr - lat_dep)) / 2), 2) +
                COS(RADIANS(lat_dep)) * COS(RADIANS(lat_arr)) *
                POWER(SIN((RADIANS(lon_arr - lon_dep)) / 2), 2)
            )
        ) AS distance_km
    FROM flight_cities
), 
avg_route AS (
    SELECT
        city1,
        city2,
        AVG(distance_km) AS avg_distance
    FROM flight_distances
    GROUP BY city1, city2
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
            ELSE '6000+'
        END AS distance_range
    FROM avg_route
), 
range_counts AS (
    SELECT
        distance_range,
        COUNT(*) AS pair_count
    FROM bucketed
    GROUP BY distance_range
)
SELECT MIN(pair_count) AS fewest_pairs
FROM range_counts;