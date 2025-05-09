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
        prev_state,
        prev_city,
        prev_lat,
        prev_lng,
        geolocation_state AS curr_state,
        geolocation_city  AS curr_city,
        geolocation_lat   AS curr_lat,
        geolocation_lng   AS curr_lng,
        ((geolocation_lat - prev_lat)*(geolocation_lat - prev_lat) +
         (geolocation_lng - prev_lng)*(geolocation_lng - prev_lng)) AS dist_sq
    FROM ordered
    WHERE prev_lat IS NOT NULL
)
SELECT
    prev_state,
    prev_city,
    ROUND(prev_lat,6) AS prev_lat,
    ROUND(prev_lng,6) AS prev_lng,
    curr_state,
    curr_city,
    ROUND(curr_lat,6) AS curr_lat,
    ROUND(curr_lng,6) AS curr_lng,
    dist_sq AS max_distance_squared_between_successive_rows
FROM distances
ORDER BY dist_sq DESC
LIMIT 1;