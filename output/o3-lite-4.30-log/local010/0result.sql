WITH coords AS (
    SELECT
        airport_code,
        json_extract(city,'$.en')                       AS city_en,
        REPLACE(REPLACE(coordinates,'(',''),')','')     AS coord_str
    FROM airports_data
),
airport_clean AS (
    SELECT
        airport_code,
        city_en,
        CAST(substr(coord_str,1,instr(coord_str,',')-1) AS REAL) AS lon_deg,
        CAST(substr(coord_str,instr(coord_str,',')+1)   AS REAL) AS lat_deg
    FROM coords
),
flight_diff AS (
    SELECT
        CASE WHEN dep.city_en < arr.city_en THEN dep.city_en ELSE arr.city_en END AS city_from,
        CASE WHEN dep.city_en < arr.city_en THEN arr.city_en ELSE dep.city_en END AS city_to,
        ABS(dep.lat_deg - arr.lat_deg) AS dlat,
        ABS(dep.lon_deg - arr.lon_deg) AS dlon
    FROM flights f
    JOIN airport_clean dep ON dep.airport_code = f.departure_airport
    JOIN airport_clean arr ON arr.airport_code = f.arrival_airport
),
flight_dist AS (
    -- rough distance estimate: 55.6 km × (|Δlat| + |Δlon|)
    SELECT
        city_from,
        city_to,
        55.6 * (dlat + dlon) AS distance_km
    FROM flight_diff
),
avg_pair AS (
    SELECT city_from, city_to, AVG(distance_km) AS avg_dist
    FROM flight_dist
    GROUP BY city_from, city_to
),
bucketed AS (
    SELECT
        CASE
            WHEN avg_dist < 1000 THEN '0-1000'
            WHEN avg_dist < 2000 THEN '1000-2000'
            WHEN avg_dist < 3000 THEN '2000-3000'
            WHEN avg_dist < 4000 THEN '3000-4000'
            WHEN avg_dist < 5000 THEN '4000-5000'
            WHEN avg_dist < 6000 THEN '5000-6000'
            ELSE '6000+'
        END AS distance_range
    FROM avg_pair
),
range_counts AS (
    SELECT distance_range, COUNT(*) AS pair_cnt
    FROM bucketed
    GROUP BY distance_range
),
result AS (
    SELECT distance_range, pair_cnt
    FROM range_counts
    ORDER BY pair_cnt, distance_range
    LIMIT 1
)
SELECT distance_range AS range_with_fewest_pairs,
       pair_cnt       AS pair_count
FROM result;