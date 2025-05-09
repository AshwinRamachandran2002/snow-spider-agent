WITH abakan AS (
    SELECT
        CAST(substr(coordinates, 2, instr(coordinates, ',') - 2) AS REAL) AS lon,
        CAST(rtrim(substr(coordinates,
                          instr(coordinates, ',') + 1), ')')           AS REAL) AS lat
    FROM   airports_data
    WHERE  airport_code = 'ABA'
),
partners AS (
    SELECT
        airport_code,
        CAST(substr(coordinates, 2, instr(coordinates, ',') - 2) AS REAL) AS lon,
        CAST(rtrim(substr(coordinates,
                          instr(coordinates, ',') + 1), ')')           AS REAL) AS lat
    FROM   airports_data
    WHERE  airport_code IN (
              SELECT DISTINCT
                     CASE
                          WHEN departure_airport = 'ABA' THEN arrival_airport
                          ELSE departure_airport
                     END
              FROM   flights
              WHERE  departure_airport = 'ABA'
                 OR  arrival_airport   = 'ABA'
          )
),
distances AS (
    SELECT
        ROUND(
              6371 * acos(
                     cos(a.lat * 0.017453292519943295) *
                     cos(p.lat * 0.017453292519943295) *
                     cos((p.lon - a.lon) * 0.017453292519943295) +
                     sin(a.lat * 0.017453292519943295) *
                     sin(p.lat * 0.017453292519943295)
              ),
              4
        ) AS distance_km
    FROM   abakan  AS a
    CROSS  JOIN partners AS p
)
SELECT MAX(distance_km) AS longest_route_km
FROM   distances;