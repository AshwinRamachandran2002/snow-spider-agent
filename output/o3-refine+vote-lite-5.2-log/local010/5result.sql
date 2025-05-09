WITH airports AS (
    /* airport longitude and latitude in decimal degrees */
    SELECT
        airport_code,
        json_extract(city,'$.en')                                                   AS city_name,
        CAST(substr(coordinates, 2, instr(coordinates, ',') - 2)               AS REAL) AS lon,
        CAST(substr(coordinates, instr(coordinates, ',') + 1,
                    length(coordinates) - instr(coordinates, ',') - 1)         AS REAL) AS lat
    FROM airports_data
),
routes AS (
    /* city pairs and helper values */
    SELECT
        CASE WHEN d.city_name < a.city_name THEN d.city_name ELSE a.city_name END AS city1,
        CASE WHEN d.city_name < a.city_name THEN a.city_name ELSE d.city_name END AS city2,
        (d.lat - a.lat)                                                        AS dlat,
        (d.lon - a.lon)                                                        AS dlon,
        ((d.lat + a.lat) / 2.0 * 0.017453292519943295)                         AS mid_rad   -- mean latitude in radians
    FROM flights f
    JOIN airports d ON f.departure_airport = d.airport_code
    JOIN airports a ON f.arrival_airport   = a.airport_code
    WHERE f.departure_airport <> f.arrival_airport
),
routes2 AS (
    /* cosine( mean‑latitude ) via a Taylor series: 1 − x²/2 + x⁴/24 − x⁶/720 */
    SELECT
        city1,
        city2,
        dlat,
        dlon,
        ( 1
          - (mid_rad*mid_rad)/2.0
          + (mid_rad*mid_rad*mid_rad*mid_rad)/24.0
          - (mid_rad*mid_rad*mid_rad*mid_rad*mid_rad*mid_rad)/720.0
        ) AS cos_lat
    FROM routes
),
route_dist AS (
    /* distance‑squared in km², using equirectangular approximation             */
    /* 1° of arc ≈ 111.2 km                                                    */
    SELECT
        city1,
        city2,
        ( (dlat*111.2)*(dlat*111.2) +
          (dlon*cos_lat*111.2)*(dlon*cos_lat*111.2)
        ) AS dist_sq_km
    FROM routes2
),
pair_avg AS (
    /* average distance‑squared for every unique city pair                     */
    SELECT city1, city2, AVG(dist_sq_km) AS avg_dist_sq
    FROM route_dist
    GROUP BY city1, city2
),
bucketed AS (
    /* place each pair into the requested kilometre buckets                    */
    SELECT
        CASE
            WHEN avg_dist_sq <  1000000 THEN '0'        -- < 1 000 km
            WHEN avg_dist_sq <  4000000 THEN '1000'     -- 1 000‑1 999 km
            WHEN avg_dist_sq <  9000000 THEN '2000'     -- 2 000‑2 999 km
            WHEN avg_dist_sq < 16000000 THEN '3000'     -- 3 000‑3 999 km
            WHEN avg_dist_sq < 25000000 THEN '4000'     -- 4 000‑4 999 km
            WHEN avg_dist_sq < 36000000 THEN '5000'     -- 5 000‑5 999 km
            ELSE '6000+'                                -- ≥ 6 000 km
        END AS distance_range
    FROM pair_avg
),
counts AS (
    /* number of pairs per bucket                                              */
    SELECT distance_range, COUNT(*) AS pair_cnt
    FROM bucketed
    GROUP BY distance_range
)
SELECT MIN(pair_cnt) AS min_pairs_in_least_populated_range
FROM counts;