WITH coords AS (
    SELECT
        airport_code,
        CAST(SUBSTR(coordinates, 2, INSTR(coordinates, ',') - 2) AS REAL) AS lon,
        CAST(
            SUBSTR(
                coordinates,
                INSTR(coordinates, ',') + 1,
                INSTR(coordinates, ')') - INSTR(coordinates, ',') - 1
            ) AS REAL
        ) AS lat
    FROM airports_data
),
pairs AS (
    SELECT
        f.flight_id,
        c1.lat AS lat1,
        c1.lon AS lon1,
        c2.lat AS lat2,
        c2.lon AS lon2
    FROM flights AS f
    JOIN coords AS c1 ON c1.airport_code = f.departure_airport
    JOIN coords AS c2 ON c2.airport_code = f.arrival_airport
    WHERE f.departure_airport = 'ABA'
       OR f.arrival_airport   = 'ABA'
),
distances AS (
    SELECT
        6371 * ACOS(
            COS(lat1 * 0.0174532925199433) * COS(lat2 * 0.0174532925199433) *
            COS((lon2 - lon1) * 0.0174532925199433) +
            SIN(lat1 * 0.0174532925199433) * SIN(lat2 * 0.0174532925199433)
        ) AS distance_km
    FROM pairs
)
SELECT
    MAX(distance_km) AS longest_abakan_route_km
FROM distances;