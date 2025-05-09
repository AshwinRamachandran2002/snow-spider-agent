WITH ordered AS (
    SELECT
        geolocation_state,
        geolocation_city,
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        ROW_NUMBER() OVER (
            ORDER BY geolocation_state,
                     geolocation_city,
                     geolocation_zip_code_prefix,
                     geolocation_lat,
                     geolocation_lng
        ) AS rn
    FROM olist_geolocation
),
pairs AS (
    SELECT
        o1.geolocation_city  AS city_1,
        o1.geolocation_state AS state_1,
        o2.geolocation_city  AS city_2,
        o2.geolocation_state AS state_2,
        ((o2.geolocation_lat - o1.geolocation_lat) * (o2.geolocation_lat - o1.geolocation_lat) +
         (o2.geolocation_lng - o1.geolocation_lng) * (o2.geolocation_lng - o1.geolocation_lng)) AS distance_squared
    FROM ordered o2
    JOIN ordered o1
      ON o1.rn = o2.rn - 1          -- consecutive rows in the ordering
)
SELECT
    city_1,
    state_1,
    city_2,
    state_2,
    distance_squared
FROM pairs
ORDER BY distance_squared DESC
LIMIT 1;