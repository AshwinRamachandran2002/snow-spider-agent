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
        prev_state  AS state1,
        prev_city   AS city1,
        geolocation_state AS state2,
        geolocation_city  AS city2,
        -- squared Euclidean distance in degrees (avoids need for SQRT)
        ((geolocation_lat - prev_lat) * (geolocation_lat - prev_lat) +
         (geolocation_lng - prev_lng) * (geolocation_lng - prev_lng)) AS distance_sq_deg
    FROM ordered
    WHERE prev_lat IS NOT NULL
)
SELECT
    state1,
    city1,
    state2,
    city2,
    ROUND(distance_sq_deg, 4) AS max_distance_metric
FROM distances
ORDER BY distance_sq_deg DESC
LIMIT 1;