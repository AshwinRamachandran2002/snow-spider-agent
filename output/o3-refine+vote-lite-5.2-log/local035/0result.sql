WITH ordered AS (
    SELECT
        geolocation_state,
        geolocation_city,
        geolocation_zip_code_prefix,
        geolocation_lat,
        geolocation_lng,
        LAG(geolocation_state) OVER w AS prev_state,
        LAG(geolocation_city)  OVER w AS prev_city,
        LAG(geolocation_lat)   OVER w AS prev_lat,
        LAG(geolocation_lng)   OVER w AS prev_lng
    FROM olist_geolocation
    WINDOW w AS (
        ORDER BY
            geolocation_state,
            geolocation_city,
            geolocation_zip_code_prefix,
            geolocation_lat,
            geolocation_lng
    )
),
distances AS (
    SELECT
        prev_state,
        prev_city,
        geolocation_state,
        geolocation_city,
        ((geolocation_lat - prev_lat) * (geolocation_lat - prev_lat) +
         (geolocation_lng - prev_lng) * (geolocation_lng - prev_lng)) AS distance_squared
    FROM ordered
    WHERE prev_lat IS NOT NULL
),
max_dist AS (
    SELECT MAX(distance_squared) AS max_distance_squared
    FROM distances
)
SELECT
    prev_state  AS from_state,
    prev_city   AS from_city,
    geolocation_state AS to_state,
    geolocation_city  AS to_city,
    distance_squared
FROM distances
JOIN max_dist ON distance_squared = max_distance_squared;