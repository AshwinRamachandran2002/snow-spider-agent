WITH airports AS (
    SELECT
        "airport_code",
        PARSE_JSON("city"):en::string                                              AS city_en,
        CAST(SPLIT(REPLACE(REPLACE("coordinates",'(',''),')',''),',')[0] AS DOUBLE) AS lon_deg,
        CAST(SPLIT(REPLACE(REPLACE("coordinates",'(',''),')',''),',')[1] AS DOUBLE) AS lat_deg
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
flight_cities AS (
    SELECT
        f."flight_id",
        dep.city_en                                   AS dep_city,
        arr.city_en                                   AS arr_city,
        RADIANS(dep.lat_deg)                          AS dep_lat,
        RADIANS(dep.lon_deg)                          AS dep_lon,
        RADIANS(arr.lat_deg)                          AS arr_lat,
        RADIANS(arr.lon_deg)                          AS arr_lon
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN airports dep ON f."departure_airport" = dep."airport_code"
    JOIN airports arr ON f."arrival_airport" = arr."airport_code"
),
distances AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END              AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END              AS city2,
        2*6371*ASIN(
            SQRT(
                POWER(SIN((arr_lat - dep_lat)/2),2) +
                COS(dep_lat)*COS(arr_lat)*POWER(SIN((arr_lon - dep_lon)/2),2)
            )
        )                                                                          AS distance_km
    FROM flight_cities
),
avg_dist AS (
    SELECT
        city1,
        city2,
        AVG(distance_km) AS avg_distance
    FROM distances
    GROUP BY city1, city2
),
buckets AS (
    SELECT
        city1,
        city2,
        avg_distance,
        CASE
            WHEN avg_distance >= 6000 THEN '6000+'
            WHEN avg_distance >= 5000 THEN '5000'
            WHEN avg_distance >= 4000 THEN '4000'
            WHEN avg_distance >= 3000 THEN '3000'
            WHEN avg_distance >= 2000 THEN '2000'
            WHEN avg_distance >= 1000 THEN '1000'
            ELSE '0'
        END AS distance_range
    FROM avg_dist
),
range_counts AS (
    SELECT
        distance_range,
        COUNT(*) AS pair_count
    FROM buckets
    GROUP BY distance_range
)
SELECT
    MIN(pair_count) AS "min_pairs_in_distance_range"
FROM range_counts;