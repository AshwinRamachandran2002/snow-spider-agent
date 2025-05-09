WITH ordered AS (
    SELECT
        geolocation_state,
        geolocation_city,
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        LAG(geolocation_state) OVER (
            ORDER BY geolocation_state,
                     geolocation_city,
                     geolocation_zip_code_prefix,
                     geolocation_lat,
                     geolocation_lng
        ) AS prev_state,
        LAG(geolocation_city) OVER (
            ORDER BY geolocation_state,
                     geolocation_city,
                     geolocation_zip_code_prefix,
                     geolocation_lat,
                     geolocation_lng
        ) AS prev_city,
        LAG(geolocation_lat) OVER (
            ORDER BY geolocation_state,
                     geolocation_city,
                     geolocation_zip_code_prefix,
                     geolocation_lat,
                     geolocation_lng
        ) AS prev_lat,
        LAG(geolocation_lng) OVER (
            ORDER BY geolocation_state,
                     geolocation_city,
                     geolocation_zip_code_prefix,
                     geolocation_lat,
                     geolocation_lng
        ) AS prev_lng
    FROM olist_geolocation
),
distances AS (
    SELECT
        prev_city   AS city_1,
        prev_state  AS state_1,
        geolocation_city  AS city_2,
        geolocation_state AS state_2,
        /* squared Euclidean distance in degrees */
        ((geolocation_lat - prev_lat)*(geolocation_lat - prev_lat) +
         (geolocation_lng - prev_lng)*(geolocation_lng - prev_lng)) AS dist_sq
    FROM ordered
    WHERE prev_lat IS NOT NULL
)
SELECT city_1, state_1, city_2, state_2
FROM distances
ORDER BY dist_sq DESC
LIMIT 1;