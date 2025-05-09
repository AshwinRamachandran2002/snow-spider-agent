WITH coords AS (
    SELECT
        airport_code,
        CAST(substr(coordinates, 2,
                    instr(coordinates, ',') - 2) AS REAL)                 AS lon,
        CAST(substr(coordinates,
                    instr(coordinates, ',') + 1,
                    instr(coordinates, ')') - instr(coordinates, ',') - 1) AS REAL) AS lat,
        json_extract(city, '$.en')                                        AS city_en
    FROM airports_data
)
SELECT ROUND(MAX(
           6371 * acos(
               cos((d.lat * 3.141592653589793) / 180) *
               cos((a.lat * 3.141592653589793) / 180) *
               cos(((a.lon - d.lon) * 3.141592653589793) / 180) +
               sin((d.lat * 3.141592653589793) / 180) *
               sin((a.lat * 3.141592653589793) / 180)
           )
       ), 4) AS longest_distance_km
FROM flights AS f
JOIN coords AS d ON d.airport_code = f.departure_airport
JOIN coords AS a ON a.airport_code = f.arrival_airport
WHERE d.city_en = 'Abakan'
   OR a.city_en = 'Abakan';