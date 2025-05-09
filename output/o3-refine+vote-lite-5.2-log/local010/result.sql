WITH airports AS (
    SELECT
        airport_code,
        json_extract(city,'$.en') AS city,
        CAST(substr(coordinates,2, instr(coordinates,',')-2) AS REAL)  AS lon,
        CAST(substr(coordinates, instr(coordinates,',')+1, 
             length(coordinates)-instr(coordinates,',')-1) AS REAL)   AS lat
    FROM airports_data
),
routes AS (
    SELECT DISTINCT
        departure_airport,
        arrival_airport
    FROM flights
),
routes_coords AS (
    SELECT
        r.departure_airport,
        r.arrival_airport,
        da.city AS dep_city,
        aa.city AS arr_city,
        da.lat  AS dep_lat,
        da.lon  AS dep_lon,
        aa.lat  AS arr_lat,
        aa.lon  AS arr_lon
    FROM routes r
    JOIN airports da ON da.airport_code = r.departure_airport
    JOIN airports aa ON aa.airport_code = r.arrival_airport
    WHERE da.city IS NOT NULL
      AND aa.city IS NOT NULL
),
city_pairs AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city2,
        /* squared difference in degrees – avoids unavailable trig functions */
        (
          (dep_lat - arr_lat)*(dep_lat - arr_lat) +
          (dep_lon - arr_lon)*(dep_lon - arr_lon)
        ) AS deg_sq
    FROM routes_coords
    WHERE dep_city <> arr_city
),
avg_city_distance AS (
    SELECT city1, city2, AVG(deg_sq) AS avg_deg_sq
    FROM city_pairs
    GROUP BY city1, city2
),
bucketed AS (
    /* compare the squared‑degree distance with squared thresholds:
       (km/111)² for 1000, 2000 … 6000 km                       */
    SELECT
        city1,
        city2,
        CASE
            WHEN avg_deg_sq < (1000.0/111.0)*(1000.0/111.0) THEN '0'
            WHEN avg_deg_sq < (2000.0/111.0)*(2000.0/111.0) THEN '1000'
            WHEN avg_deg_sq < (3000.0/111.0)*(3000.0/111.0) THEN '2000'
            WHEN avg_deg_sq < (4000.0/111.0)*(4000.0/111.0) THEN '3000'
            WHEN avg_deg_sq < (5000.0/111.0)*(5000.0/111.0) THEN '4000'
            WHEN avg_deg_sq < (6000.0/111.0)*(6000.0/111.0) THEN '5000'
            ELSE '6000+'
        END AS bucket
    FROM avg_city_distance
),
bucket_counts AS (
    SELECT bucket, COUNT(*) AS pair_count
    FROM bucketed
    GROUP BY bucket
)
SELECT MIN(pair_count) AS fewest_pairs
FROM bucket_counts;