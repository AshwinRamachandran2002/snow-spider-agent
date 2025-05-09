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
        prev_city   AS first_city,
        prev_state  AS first_state,
        geolocation_city  AS second_city,
        geolocation_state AS second_state,
        ((geolocation_lat - prev_lat)*(geolocation_lat - prev_lat) +
         (geolocation_lng - prev_lng)*(geolocation_lng - prev_lng)) AS distance
    FROM ordered
    WHERE prev_lat IS NOT NULL
)
SELECT
    first_city,
    first_state,
    second_city,
    second_state,
    distance
FROM distances
ORDER BY distance DESC
LIMIT 1;