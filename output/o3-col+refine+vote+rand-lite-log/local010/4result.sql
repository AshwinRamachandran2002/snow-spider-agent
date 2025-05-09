WITH flight_distances AS (
    /* distance (in km) for every scheduled route */
    SELECT
        json_extract(dep.city, '$.en') AS city_from,
        json_extract(arr.city, '$.en') AS city_to,
        6371 * acos(
            cos(radians( CAST(substr(dep.coordinates,
                                     instr(dep.coordinates, ',')+1,
                                     instr(dep.coordinates, ')')
                                     - instr(dep.coordinates, ',') - 1) AS REAL)))
          * cos(radians( CAST(substr(arr.coordinates,
                                     instr(arr.coordinates, ',')+1,
                                     instr(arr.coordinates, ')')
                                     - instr(arr.coordinates, ',') - 1) AS REAL)))
          * cos(radians( CAST(substr(arr.coordinates, 2,
                                     instr(arr.coordinates, ',')-2) AS REAL))
               - radians( CAST(substr(dep.coordinates, 2,
                                      instr(dep.coordinates, ',')-2) AS REAL)))
          + sin(radians( CAST(substr(dep.coordinates,
                                     instr(dep.coordinates, ',')+1,
                                     instr(dep.coordinates, ')')
                                     - instr(dep.coordinates, ',') - 1) AS REAL)))
          * sin(radians( CAST(substr(arr.coordinates,
                                     instr(arr.coordinates, ',')+1,
                                     instr(arr.coordinates, ')')
                                     - instr(arr.coordinates, ',') - 1) AS REAL)))
        ) AS distance_km
    FROM flights f
    JOIN airports_data dep ON dep.airport_code = f.departure_airport
    JOIN airports_data arr ON arr.airport_code = f.arrival_airport
),
unordered_pairs AS (
    /* make the city pair order-independent */
    SELECT
        CASE WHEN city_from < city_to THEN city_from ELSE city_to END AS city_a,
        CASE WHEN city_from < city_to THEN city_to ELSE city_from END AS city_b,
        distance_km
    FROM flight_distances
),
pair_avg AS (
    /* average distance for every unique pair */
    SELECT
        city_a,
        city_b,
        AVG(distance_km) AS avg_km
    FROM unordered_pairs
    GROUP BY city_a, city_b
),
bucketed AS (
    /* put each pair into the requested 1 000-km buckets */
    SELECT
        CASE
            WHEN avg_km >= 6000 THEN '6000+'
            ELSE printf('%d', (CAST(avg_km/1000 AS INTEGER))*1000)
        END AS distance_bucket
    FROM pair_avg
),
bucket_counts AS (
    /* count how many pairs fall into each bucket */
    SELECT
        distance_bucket,
        COUNT(*) AS pair_cnt
    FROM bucketed
    GROUP BY distance_bucket
)
SELECT MIN(pair_cnt) AS fewest_pairs
FROM bucket_counts;