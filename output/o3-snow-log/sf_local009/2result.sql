WITH airports AS (
    SELECT
        "airport_code",
        TO_VARCHAR(PARSE_JSON("city"):en)                                   AS city_en,
        TO_DOUBLE(REGEXP_SUBSTR("coordinates", '[-0-9.]+', 1, 1))          AS lon,
        TO_DOUBLE(REGEXP_SUBSTR("coordinates", '[-0-9.]+', 1, 2))          AS lat
    FROM AIRLINES.AIRLINES.AIRPORTS_DATA
),
aba_routes AS (
    SELECT
        f."flight_id",
        dep.lat  AS dep_lat,
        dep.lon  AS dep_lon,
        arr.lat  AS arr_lat,
        arr.lon  AS arr_lon
    FROM AIRLINES.AIRLINES.FLIGHTS f
    JOIN airports dep ON dep."airport_code" = f."departure_airport"
    JOIN airports arr ON arr."airport_code" = f."arrival_airport"
    WHERE dep.city_en = 'Abakan' OR arr.city_en = 'Abakan'
),
distances AS (
    SELECT
        2 * 6371 * ASIN(
              SQRT(
                  POWER(SIN((RADIANS(arr_lat) - RADIANS(dep_lat)) / 2), 2)
                + COS(RADIANS(dep_lat)) * COS(RADIANS(arr_lat))
                  * POWER(SIN((RADIANS(arr_lon) - RADIANS(dep_lon)) / 2), 2)
              )
        ) AS distance_km
    FROM aba_routes
)
SELECT ROUND(MAX(distance_km), 4) AS longest_distance_km
FROM distances;