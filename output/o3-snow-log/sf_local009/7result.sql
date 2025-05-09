WITH abakan_airports AS (   -- airports that serve the city “Abakan”
    SELECT "airport_code"
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
    WHERE LOWER("city") LIKE '%abakan%'
),
coords AS (                 -- longitude / latitude for every airport
    SELECT
        "airport_code",
        TRIM(SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''), ',', 0))::FLOAT AS lon,
        TRIM(SPLIT_PART(REPLACE(REPLACE("coordinates",'(',''),')',''), ',', 1))::FLOAT AS lat
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
flights_abakan AS (         -- every flight where Abakan is either origin or destination
    SELECT DISTINCT
        f."departure_airport",
        f."arrival_airport"
    FROM AIRLINES.AIRLINES.FLIGHTS f
    WHERE f."departure_airport" IN (SELECT "airport_code" FROM abakan_airports)
       OR f."arrival_airport"   IN (SELECT "airport_code" FROM abakan_airports)
),
distances AS (              -- great-circle distance (Haversine) for each of those routes
    SELECT
        2 * 6371 * ASIN(
            SQRT(
                  POWER(SIN((RADIANS(ca.lat) - RADIANS(cd.lat)) / 2), 2)
                + COS(RADIANS(cd.lat))
                * COS(RADIANS(ca.lat))
                * POWER(SIN((RADIANS(ca.lon) - RADIANS(cd.lon)) / 2), 2)
            )
        ) AS distance_km
    FROM flights_abakan fa
    JOIN coords cd ON cd."airport_code" = fa."departure_airport"
    JOIN coords ca ON ca."airport_code" = fa."arrival_airport"
)
SELECT MAX(distance_km) AS "LONGEST_ROUTE_DISTANCE_KM"
FROM distances;