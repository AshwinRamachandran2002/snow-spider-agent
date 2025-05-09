WITH RECURSIVE
-- 1. airport → city , lon(°) , lat(°)
ap AS (
    SELECT
        airport_code,
        json_extract(city,'$.en')                             AS city,
        CAST(substr(coordinates,2,instr(coordinates,',')-2)  AS REAL) AS lon_deg,
        CAST(substr(coordinates,
                    instr(coordinates,',')+1,
                    length(coordinates)-instr(coordinates,',')-1)     AS REAL) AS lat_deg
    FROM airports_data
),
-- 2. every scheduled leg (unordered city pair) and the degree deltas
legs AS (
    SELECT
        CASE WHEN da.city < aa.city THEN da.city ELSE aa.city END AS city1,
        CASE WHEN da.city < aa.city THEN aa.city ELSE da.city END AS city2,
        (aa.lat_deg - da.lat_deg)  AS dlat,
        (aa.lon_deg - da.lon_deg)  AS dlon
    FROM flights f
    JOIN ap da ON da.airport_code = f.departure_airport
    JOIN ap aa ON aa.airport_code = f.arrival_airport
    WHERE da.city <> aa.city
),
-- 3. h = (Δlat)² + (Δlon)²  (still in degree²)
hvals AS (
    SELECT
        city1,
        city2,
        (dlat*dlat) + (dlon*dlon) AS h
    FROM legs
),
-- 4. Newton iterations to obtain √h without using sqrt()
sqrt_iter(city1,city2,h,y,step) AS (
    SELECT
        city1, city2, h,
        CASE WHEN h = 0 THEN 0.0 ELSE h/2.0 END AS y,
        0 AS step
    FROM hvals
    UNION ALL
    SELECT
        city1, city2, h,
        CASE WHEN y = 0 THEN 0.0 ELSE (y + h/y)/2.0 END,
        step + 1
    FROM sqrt_iter
    WHERE step < 8                      -- 8 iterations are enough for convergence
),
root AS (
    SELECT city1, city2, y AS root_h
    FROM sqrt_iter
    WHERE step = 8
),
-- 5. flat‑earth distance ≈ 111.1 km × √h ; average per unordered city pair
pair_avg AS (
    SELECT
        city1,
        city2,
        AVG(111.1 * root_h) AS avg_distance
    FROM root
    GROUP BY city1, city2
),
-- 6. bucket the average distance
bucketed AS (
    SELECT
        CASE
            WHEN avg_distance < 1000 THEN '0-999'
            WHEN avg_distance < 2000 THEN '1000-1999'
            WHEN avg_distance < 3000 THEN '2000-2999'
            WHEN avg_distance < 4000 THEN '3000-3999'
            WHEN avg_distance < 5000 THEN '4000-4999'
            WHEN avg_distance < 6000 THEN '5000-5999'
            ELSE                         '6000+'
        END AS distance_range
    FROM pair_avg
),
-- 7. count pairs in every bucket
counts AS (
    SELECT distance_range, COUNT(*) AS pair_cnt
    FROM bucketed
    GROUP BY distance_range
)
-- 8. bucket with the fewest pairs
SELECT
    distance_range AS range_with_fewest_pairs,
    pair_cnt       AS pair_count
FROM counts
ORDER BY pair_cnt ASC, distance_range
LIMIT 1;