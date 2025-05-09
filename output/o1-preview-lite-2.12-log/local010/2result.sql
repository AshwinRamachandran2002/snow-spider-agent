WITH airport_coords AS (
    SELECT
        airport_code,
        json_extract(city, '$.en') AS city_name,
        CAST(
            substr(coordinates, 2, instr(coordinates, ',') - 2) AS REAL
        ) AS longitude,
        CAST(
            substr(coordinates, instr(coordinates, ',') + 1, length(coordinates) - instr(coordinates, ',') - 1) AS REAL
        ) AS latitude
    FROM airports_data
),
flight_coords AS (
    SELECT
        f.flight_id,
        dep.city_name AS dep_city,
        dep.longitude AS dep_lon,
        dep.latitude AS dep_lat,
        arr.city_name AS arr_city,
        arr.longitude AS arr_lon,
        arr.latitude AS arr_lat
    FROM flights f
    JOIN airport_coords dep ON f.departure_airport = dep.airport_code
    JOIN airport_coords arr ON f.arrival_airport = arr.airport_code
),
city_pairs AS (
    SELECT
        CASE WHEN dep_city < arr_city THEN dep_city ELSE arr_city END AS city1,
        CASE WHEN dep_city < arr_city THEN arr_city ELSE dep_city END AS city2,
        AVG((ABS(dep_lat - arr_lat) + ABS(dep_lon - arr_lon)) * 111.0) AS avg_distance
    FROM flight_coords
    GROUP BY city1, city2
)
SELECT
    CASE
        WHEN avg_distance <= 1000 THEN '0-1000'
        WHEN avg_distance <= 2000 THEN '1000-2000'
        WHEN avg_distance <= 3000 THEN '2000-3000'
        WHEN avg_distance <= 4000 THEN '3000-4000'
        WHEN avg_distance <= 5000 THEN '4000-5000'
        WHEN avg_distance <= 6000 THEN '5000-6000'
        ELSE '6000+'
    END AS Distance_Range,
    COUNT(*) AS Number_of_City_Pairs
FROM city_pairs
GROUP BY Distance_Range
ORDER BY Distance_Range;