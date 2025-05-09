WITH flight_data AS (
    SELECT
        f."flight_id",
        LEAST(da."city", aa."city") AS "city1",
        GREATEST(da."city", aa."city") AS "city2",
        REPLACE(REPLACE(da."coordinates", '(', ''), ')', '') AS "dep_coords",
        REPLACE(REPLACE(aa."coordinates", '(', ''), ')', '') AS "arr_coords"
    FROM "AIRLINES"."AIRLINES"."FLIGHTS" f
    JOIN "AIRLINES"."AIRLINES"."AIRPORTS_DATA" da
        ON f."departure_airport" = da."airport_code"
    JOIN "AIRLINES"."AIRLINES"."AIRPORTS_DATA" aa
        ON f."arrival_airport" = aa."airport_code"
),
parsed_coords AS (
    SELECT
        "city1",
        "city2",
        "flight_id",
        TO_DOUBLE(SPLIT("dep_coords", ',')[0]) AS dep_longitude,
        TO_DOUBLE(SPLIT("dep_coords", ',')[1]) AS dep_latitude,
        TO_DOUBLE(SPLIT("arr_coords", ',')[0]) AS arr_longitude,
        TO_DOUBLE(SPLIT("arr_coords", ',')[1]) AS arr_latitude
    FROM flight_data
),
radians_coords AS (
    SELECT
        "city1",
        "city2",
        "flight_id",
        RADIANS(dep_latitude) AS dep_lat_rad,
        RADIANS(dep_longitude) AS dep_lon_rad,
        RADIANS(arr_latitude) AS arr_lat_rad,
        RADIANS(arr_longitude) AS arr_lon_rad
    FROM parsed_coords
),
distances AS (
    SELECT
        "city1",
        "city2",
        "flight_id",
        ROUND(
            6371 * 2 * ATAN2(
                SQRT(
                    SIN((arr_lat_rad - dep_lat_rad) / 2) * SIN((arr_lat_rad - dep_lat_rad) / 2)
                    + COS(dep_lat_rad) * COS(arr_lat_rad) * SIN((arr_lon_rad - dep_lon_rad) / 2) * SIN((arr_lon_rad - dep_lon_rad) / 2)
                ),
                SQRT(1 - (
                    SIN((arr_lat_rad - dep_lat_rad) / 2) * SIN((arr_lat_rad - dep_lat_rad) / 2)
                    + COS(dep_lat_rad) * COS(arr_lat_rad) * SIN((arr_lon_rad - dep_lon_rad) / 2) * SIN((arr_lon_rad - dep_lon_rad) / 2)
                ))
            ),
            4
        ) AS distance_km
    FROM radians_coords
),
avg_distances AS (
    SELECT
        "city1",
        "city2",
        ROUND(AVG(distance_km), 4) AS avg_distance
    FROM distances
    GROUP BY "city1", "city2"
),
binned_pairs AS (
    SELECT
        "city1",
        "city2",
        avg_distance,
        CASE
            WHEN avg_distance <= 1000 THEN '0'
            WHEN avg_distance > 1000 AND avg_distance <= 2000 THEN '1000'
            WHEN avg_distance > 2000 AND avg_distance <= 3000 THEN '2000'
            WHEN avg_distance > 3000 AND avg_distance <= 4000 THEN '3000'
            WHEN avg_distance > 4000 AND avg_distance <= 5000 THEN '4000'
            WHEN avg_distance > 5000 AND avg_distance <= 6000 THEN '5000'
            ELSE '6000+'
        END AS distance_range
    FROM avg_distances
),
range_counts AS (
    SELECT
        distance_range,
        COUNT(*) AS num_pairs
    FROM binned_pairs
    GROUP BY distance_range
),
min_range AS (
    SELECT
        distance_range,
        num_pairs
    FROM range_counts
    WHERE num_pairs = (SELECT MIN(num_pairs) FROM range_counts)
)
SELECT num_pairs AS "Number_of_Pairs_in_Smallest_Range"
FROM min_range;