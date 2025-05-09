WITH aba AS (                       -- Abakan coordinates
    SELECT
        CAST(SUBSTR(coordinates, 2, INSTR(coordinates, ',') - 2) AS REAL)  AS lon1,
        CAST(SUBSTR(coordinates,
                     INSTR(coordinates, ',') + 1,
                     INSTR(coordinates, ')') - INSTR(coordinates, ',') - 1) AS REAL) AS lat1
    FROM   airports_data
    WHERE  airport_code = 'ABA'
),
paired AS (                         -- every airport ever paired with Abakan
    SELECT DISTINCT
           CASE WHEN departure_airport = 'ABA'
                THEN arrival_airport
                ELSE departure_airport
           END AS other_code
    FROM   flights
    WHERE  departure_airport = 'ABA'
       OR  arrival_airport   = 'ABA'
),
other_coords AS (                   -- coordinates of each paired airport
    SELECT  p.other_code,
            CAST(SUBSTR(a.coordinates, 2, INSTR(a.coordinates, ',') - 2) AS REAL)  AS lon2,
            CAST(SUBSTR(a.coordinates,
                         INSTR(a.coordinates, ',') + 1,
                         INSTR(a.coordinates, ')') - INSTR(a.coordinates, ',') - 1) AS REAL) AS lat2
    FROM    paired p
    JOIN    airports_data a ON a.airport_code = p.other_code
),
distances AS (                      -- great-circle distances, km
    SELECT
        6371 *
        ACOS(
            COS(lat1 * 3.141592653589793/180) *
            COS(lat2 * 3.141592653589793/180) *
            COS((lon2 - lon1) * 3.141592653589793/180) +
            SIN(lat1 * 3.141592653589793/180) *
            SIN(lat2 * 3.141592653589793/180)
        ) AS distance_km
    FROM   aba, other_coords
)
SELECT ROUND(MAX(distance_km), 4) AS longest_abakan_route_km
FROM   distances;