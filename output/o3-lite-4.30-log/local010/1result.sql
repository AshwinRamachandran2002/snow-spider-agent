WITH airport_coords AS (
    SELECT
        airport_code,
        CAST(substr(coordinates, 2,
                    instr(coordinates, ',') - 2) AS REAL)          AS lon,
        CAST(substr(coordinates,
                    instr(coordinates, ',') + 1,
                    length(coordinates) - instr(coordinates, ',') - 1) AS REAL) AS lat,
        json_extract(city,'$.en')                                  AS city_en
    FROM airports_data
),
flight_dist AS (
    /*  Approximate distance: latitude difference (°) converted to km             */
    /*  (1° latitude ≈ 111.2 km).                                                 */
    SELECT
        f.flight_id,
        d.city_en                                              AS dep_city,
        a.city_en                                              AS arr_city,
        ABS(d.lat - a.lat) * 111.2                             AS distance_km
    FROM flights        AS f
    JOIN airport_coords AS d ON d.airport_code = f.departure_airport
    JOIN airport_coords AS a ON a.airport_code = f.arrival_airport
    WHERE f.departure_airport <> f.arrival_airport
),
pair_avg AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city2,
        AVG(distance_km)                                            AS avg_km
    FROM flight_dist
    GROUP BY city1, city2
),
bucketed AS (
    SELECT
        city1,
        city2,
        CASE
            WHEN avg_km <= 1000 THEN '0-1000'
            WHEN avg_km <= 2000 THEN '1000-2000'
            WHEN avg_km <= 3000 THEN '2000-3000'
            WHEN avg_km <= 4000 THEN '3000-4000'
            WHEN avg_km <= 5000 THEN '4000-5000'
            WHEN avg_km <= 6000 THEN '5000-6000'
            ELSE                     '6000+'
        END                                                     AS dist_range
    FROM pair_avg
),
range_counts AS (
    SELECT dist_range, COUNT(*) AS pair_count
    FROM bucketed
    GROUP BY dist_range
)
SELECT dist_range  AS range_with_fewest_pairs,
       pair_count
FROM range_counts
WHERE pair_count = (SELECT MIN(pair_count) FROM range_counts);