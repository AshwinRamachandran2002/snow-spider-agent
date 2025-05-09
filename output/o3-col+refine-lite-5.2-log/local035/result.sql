WITH ordered AS (
    SELECT
        geolocation_state,
        geolocation_city,
        geolocation_lat,
        geolocation_lng,
        LAG(geolocation_state) OVER w AS prev_state,
        LAG(geolocation_city)  OVER w AS prev_city,
        LAG(geolocation_lat)   OVER w AS prev_lat,
        LAG(geolocation_lng)   OVER w AS prev_lng
    FROM olist_geolocation
    WINDOW w AS (
        ORDER BY geolocation_state,
                 geolocation_city,
                 geolocation_zip_code_prefix,
                 geolocation_lat,
                 geolocation_lng
    )
),
distances AS (
    SELECT
        prev_city  AS city_A,
        prev_state AS state_A,
        geolocation_city  AS city_B,
        geolocation_state AS state_B,
        ((geolocation_lat - prev_lat)*(geolocation_lat - prev_lat) +
         (geolocation_lng - prev_lng)*(geolocation_lng - prev_lng)) AS distance_sq
    FROM ordered
    WHERE prev_lat IS NOT NULL
)
SELECT
    city_A,
    state_A,
    city_B,
    state_B,
    distance_sq AS greatest_distance_sq
FROM distances
ORDER BY distance_sq DESC
LIMIT 1;