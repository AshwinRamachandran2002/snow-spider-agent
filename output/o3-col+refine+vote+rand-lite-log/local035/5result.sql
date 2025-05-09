WITH ordered AS (
    SELECT 
        "geolocation_state"                                           AS curr_state,
        "geolocation_city"                                            AS curr_city,
        "geolocation_lat"                                             AS curr_lat,
        "geolocation_lng"                                             AS curr_lng,
        LAG("geolocation_state") OVER w                               AS prev_state,
        LAG("geolocation_city")  OVER w                               AS prev_city,
        LAG("geolocation_lat")   OVER w                               AS prev_lat,
        LAG("geolocation_lng")   OVER w                               AS prev_lng
    FROM "olist_geolocation"
    WINDOW w AS (
        ORDER BY 
            "geolocation_state",
            "geolocation_city",
            "geolocation_zip_code_prefix",
            "geolocation_lat",
            "geolocation_lng"
    )
),
distances AS (
    SELECT
        prev_state,
        prev_city,
        curr_state,
        curr_city,
        SQRT(
            (curr_lat - prev_lat) * (curr_lat - prev_lat) +
            (curr_lng - prev_lng) * (curr_lng - prev_lng)
        ) AS distance_diff
    FROM ordered
    WHERE prev_city IS NOT NULL
      AND curr_city <> prev_city
)
SELECT
    prev_state  AS state_prev,
    prev_city   AS city_prev,
    curr_state  AS state_curr,
    curr_city   AS city_curr,
    distance_diff
FROM distances
ORDER BY distance_diff DESC
LIMIT 1;