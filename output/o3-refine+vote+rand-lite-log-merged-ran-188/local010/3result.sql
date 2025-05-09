WITH airport_coords AS (
    SELECT
        airport_code,
        json_extract(city,'$.en')                 AS city,
        CAST(substr(coordinates,2,
             instr(coordinates,',')-2) AS REAL)  AS lon,
        CAST(substr(coordinates,
             instr(coordinates,',')+1,
             length(coordinates)-instr(coordinates,',')-1) AS REAL) AS lat
    FROM airports_data
),
flight_distances AS (
    SELECT
        CASE WHEN d.city < a.city THEN d.city ELSE a.city END AS city1,
        CASE WHEN d.city < a.city THEN a.city ELSE d.city END AS city2,
        ( (d.lat-a.lat)*(d.lat-a.lat) + (d.lon-a.lon)*(d.lon-a.lon) )*12345.21  AS dist_sq    -- 12345.21 = 111.1²
    FROM flights f
    JOIN airport_coords d ON d.airport_code = f.departure_airport
    JOIN airport_coords a ON a.airport_code = f.arrival_airport
    WHERE d.city IS NOT NULL
      AND a.city IS NOT NULL
      AND d.city <> a.city
),
avg_distances AS (
    SELECT city1, city2, AVG(dist_sq) AS avg_dist_sq
    FROM flight_distances
    GROUP BY city1, city2
),
buckets AS (
    SELECT
        CASE
            WHEN avg_dist_sq < 1000*1000 THEN '0'
            WHEN avg_dist_sq < 2000*2000 THEN '1000'
            WHEN avg_dist_sq < 3000*3000 THEN '2000'
            WHEN avg_dist_sq < 4000*4000 THEN '3000'
            WHEN avg_dist_sq < 5000*5000 THEN '4000'
            WHEN avg_dist_sq < 6000*6000 THEN '5000'
            ELSE '6000+'
        END AS range_bucket
    FROM avg_distances
),
bucket_counts AS (
    SELECT range_bucket, COUNT(*) AS pair_cnt
    FROM buckets
    GROUP BY range_bucket
)
SELECT MIN(pair_cnt) AS fewest_pairs
FROM bucket_counts;