WITH coords AS (
    SELECT
        CAST(SUBSTR(ad1.coordinates, 2,
                    INSTR(ad1.coordinates, ',') - 2) AS REAL)               AS lon1,
        CAST(SUBSTR(ad1.coordinates,
                    INSTR(ad1.coordinates, ',') + 1,
                    INSTR(ad1.coordinates, ')') - INSTR(ad1.coordinates, ',') - 1)
             AS REAL)                                                      AS lat1,
        CAST(SUBSTR(ad2.coordinates, 2,
                    INSTR(ad2.coordinates, ',') - 2) AS REAL)               AS lon2,
        CAST(SUBSTR(ad2.coordinates,
                    INSTR(ad2.coordinates, ',') + 1,
                    INSTR(ad2.coordinates, ')') - INSTR(ad2.coordinates, ',') - 1)
             AS REAL)                                                      AS lat2
    FROM   flights AS f
    JOIN   airports_data AS ad1 ON ad1.airport_code = f.departure_airport
    JOIN   airports_data AS ad2 ON ad2.airport_code = f.arrival_airport
    WHERE  f.departure_airport = 'ABA'
       OR  f.arrival_airport   = 'ABA'
), distances AS (
    SELECT ROUND(
               6371 * ACOS(
                   SIN(lat1 * 3.141592653589793 / 180.0) *
                   SIN(lat2 * 3.141592653589793 / 180.0) +
                   COS(lat1 * 3.141592653589793 / 180.0) *
                   COS(lat2 * 3.141592653589793 / 180.0) *
                   COS((lon2 - lon1) * 3.141592653589793 / 180.0)
               )
           , 4) AS distance_km
    FROM coords
)
SELECT MAX(distance_km) AS longest_distance_km
FROM   distances;