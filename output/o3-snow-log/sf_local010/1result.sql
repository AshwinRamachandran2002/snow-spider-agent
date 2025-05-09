WITH flight_coords AS (
    SELECT
        f."flight_id",
        /* departure city & coordinates */
        PARSE_JSON(dep."city"):en::string                          AS dep_city,
        RADIANS( TO_DOUBLE( SPLIT_PART( REGEXP_REPLACE(dep."coordinates",'[()]','') , ',', 1 ) ) ) AS dep_lat_rad,
        RADIANS( TO_DOUBLE( SPLIT_PART( REGEXP_REPLACE(dep."coordinates",'[()]','') , ',', 0 ) ) ) AS dep_lon_rad,

        /* arrival city & coordinates */
        PARSE_JSON(arr."city"):en::string                          AS arr_city,
        RADIANS( TO_DOUBLE( SPLIT_PART( REGEXP_REPLACE(arr."coordinates",'[()]','') , ',', 1 ) ) ) AS arr_lat_rad,
        RADIANS( TO_DOUBLE( SPLIT_PART( REGEXP_REPLACE(arr."coordinates",'[()]','') , ',', 0 ) ) ) AS arr_lon_rad
    FROM AIRLINES.AIRLINES.FLIGHTS              f
    JOIN AIRLINES.AIRLINES.AIRPORTS_DATA  dep ON dep."airport_code" = f."departure_airport"
    JOIN AIRLINES.AIRLINES.AIRPORTS_DATA  arr ON arr."airport_code" = f."arrival_airport"
),
flight_distances AS (
    SELECT
        dep_city,
        arr_city,
        2 * 6371 * ASIN( SQRT(
              POWER( SIN( (arr_lat_rad - dep_lat_rad)/2 ), 2 )
            + COS(dep_lat_rad) * COS(arr_lat_rad)
              * POWER( SIN( (arr_lon_rad - dep_lon_rad)/2 ), 2 )
        ))                                                        AS distance_km
    FROM flight_coords
),
city_pairs AS (
    SELECT
        CASE WHEN dep_city <= arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city <= arr_city THEN arr_city ELSE dep_city END AS city2,
        distance_km
    FROM flight_distances
),
average_pair_distance AS (
    SELECT
        city1,
        city2,
        AVG(distance_km) AS avg_distance_km
    FROM city_pairs
    GROUP BY city1, city2
),
binned_pairs AS (
    SELECT
        city1,
        city2,
        CASE
            WHEN avg_distance_km < 1000 THEN '0-999'
            WHEN avg_distance_km < 2000 THEN '1000-1999'
            WHEN avg_distance_km < 3000 THEN '2000-2999'
            WHEN avg_distance_km < 4000 THEN '3000-3999'
            WHEN avg_distance_km < 5000 THEN '4000-4999'
            WHEN avg_distance_km < 6000 THEN '5000-5999'
            ELSE '6000+'
        END AS distance_range
    FROM average_pair_distance
),
range_counts AS (
    SELECT
        distance_range,
        COUNT(*) AS pair_cnt
    FROM binned_pairs
    GROUP BY distance_range
)
SELECT MIN(pair_cnt) AS fewest_pairs
FROM range_counts;