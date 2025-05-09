WITH airport_coords AS (
    /* airport code, English city name, longitude and latitude in degrees */
    SELECT
        airport_code,
        json_extract(city,'$.en')                                                    AS city,
        CAST(substr(coordinates, 2,
                    instr(coordinates, ',')-2)              AS REAL)                AS lon_deg,
        CAST(replace(substr(coordinates,
                            instr(coordinates, ',')+1),')','') AS REAL)              AS lat_deg
    FROM airports_data
),
/* every distinct pair of airports that has at least one flight */
flight_routes AS (
    SELECT DISTINCT
           departure_airport AS dep_airport,
           arrival_airport   AS arr_airport
    FROM   flights
),
/* squared planar distance (km²) between the two airports – no trig functions */
route_dist2 AS (
    SELECT
        d.city AS dep_city,
        a.city AS arr_city,

        /* °‑to‑km factor 111.2 used for both lat and lon for simplicity */
        ((a.lat_deg - d.lat_deg) * 111.2)              AS dlat_km,
        ((a.lon_deg - d.lon_deg) * 111.2)              AS dlon_km
    FROM flight_routes fr
    JOIN airport_coords d ON d.airport_code = fr.dep_airport
    JOIN airport_coords a ON a.airport_code = fr.arr_airport
),
city_pair_dist2 AS (
    /* compute the squared distance and make the pair undirected */
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city2,
        (dlat_km * dlat_km + dlon_km * dlon_km) AS dist2_km2
    FROM route_dist2
),
/* average squared distance over all airport routes between the same two cities */
avg_city_pair AS (
    SELECT city1,
           city2,
           AVG(dist2_km2) AS avg_dist2
    FROM   city_pair_dist2
    GROUP  BY city1, city2
),
/* bucket the average distance using the squared thresholds (km²) */
bucketed AS (
    SELECT
        CASE
            WHEN avg_dist2 < 1000000   THEN '0'       -- <1000 km
            WHEN avg_dist2 < 4000000   THEN '1000'    -- 1000‑2000 km
            WHEN avg_dist2 < 9000000   THEN '2000'    -- 2000‑3000 km
            WHEN avg_dist2 < 16000000  THEN '3000'    -- 3000‑4000 km
            WHEN avg_dist2 < 25000000  THEN '4000'    -- 4000‑5000 km
            WHEN avg_dist2 < 36000000  THEN '5000'    -- 5000‑6000 km
            ELSE                      '6000+'         -- ≥6000 km
        END AS bucket
    FROM avg_city_pair
),
bucket_counts AS (
    SELECT bucket,
           COUNT(*) AS pairs_in_bucket
    FROM   bucketed
    GROUP  BY bucket
)
/* final answer: fewest pairs in any bucket */
SELECT MIN(pairs_in_bucket) AS fewest_pairs
FROM   bucket_counts;