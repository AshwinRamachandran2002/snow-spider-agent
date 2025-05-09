WITH airport_coords AS (                       -- longitude & latitude in degrees
    SELECT
        airport_code,
        CAST(SUBSTR(coord, 1, INSTR(coord, ',') - 1) AS REAL) AS lon_deg,
        CAST(SUBSTR(coord, INSTR(coord, ',') + 1)    AS REAL) AS lat_deg
    FROM (
        SELECT
            airport_code,
            REPLACE(REPLACE(coordinates, '(', ''), ')', '') AS coord
        FROM airports_data
    )
),
abakan_flights AS (                             -- every flight that starts OR ends in Abakan (ABA)
    SELECT
        flight_id,
        departure_airport,
        arrival_airport
    FROM flights
    WHERE 'ABA' IN (departure_airport, arrival_airport)
),
distance_calc AS (                              -- great-circle distance (Haversine; R = 6 371 km)
    SELECT
        2 * 6371 *
        ASIN(
            SQRT(
                POWER(SIN((ac2.lat_deg - ac1.lat_deg) * 0.017453292519943295 / 2), 2) +
                COS(ac1.lat_deg * 0.017453292519943295) *
                COS(ac2.lat_deg * 0.017453292519943295) *
                POWER(SIN((ac2.lon_deg - ac1.lon_deg) * 0.017453292519943295 / 2), 2)
            )
        ) AS distance_km
    FROM abakan_flights af
    JOIN airport_coords ac1 ON ac1.airport_code = af.departure_airport
    JOIN airport_coords ac2 ON ac2.airport_code = af.arrival_airport
)
SELECT ROUND(MAX(distance_km), 4) AS longest_route_km
FROM   distance_calc;