WITH abakan_airports AS (
    SELECT airport_code
    FROM airports_data
    WHERE json_extract(city, '$.en') = 'Abakan'
),
abakan_flights AS (
    SELECT *
    FROM flights
    WHERE departure_airport IN (SELECT airport_code FROM abakan_airports)
       OR arrival_airport   IN (SELECT airport_code FROM abakan_airports)
)
SELECT MAX(a.range) AS longest_abakan_route_km
FROM abakan_flights f
JOIN aircrafts_data a ON a.aircraft_code = f.aircraft_code;