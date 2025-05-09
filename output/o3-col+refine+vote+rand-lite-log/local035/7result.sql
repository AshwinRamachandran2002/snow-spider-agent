WITH ordered AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng",
        LAG("geolocation_state") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_state,
        LAG("geolocation_city") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_city,
        LAG("geolocation_lat") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_lat,
        LAG("geolocation_lng") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_lng
    FROM "olist_geolocation"
),
distances AS (
    SELECT
        "geolocation_state"  AS current_state,
        "geolocation_city"   AS current_city,
        "geolocation_lat"    AS current_lat,
        "geolocation_lng"    AS current_lng,
        prev_state           AS previous_state,
        prev_city            AS previous_city,
        prev_lat             AS previous_lat,
        prev_lng             AS previous_lng,
        SQRT(
            ( "geolocation_lat" - prev_lat ) * ( "geolocation_lat" - prev_lat ) +
            ( "geolocation_lng" - prev_lng ) * ( "geolocation_lng" - prev_lng )
        ) AS deg_distance
    FROM ordered
    WHERE prev_lat IS NOT NULL
)
SELECT
    current_state,
    current_city,
    current_lat,
    current_lng,
    previous_state,
    previous_city,
    previous_lat,
    previous_lng,
    ROUND(deg_distance, 4) AS deg_distance
FROM distances
ORDER BY deg_distance DESC
LIMIT 1;