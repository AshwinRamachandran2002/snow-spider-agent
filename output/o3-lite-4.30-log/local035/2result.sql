WITH ordered AS (
    SELECT
        "geolocation_state" AS cur_state,
        "geolocation_city"  AS cur_city,
        "geolocation_lat"   AS cur_lat,
        "geolocation_lng"   AS cur_lng,
        LAG("geolocation_state") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")            AS prev_state,
        LAG("geolocation_city")  OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")            AS prev_city,
        LAG("geolocation_lat")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")            AS prev_lat,
        LAG("geolocation_lng")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")            AS prev_lng
    FROM "olist_geolocation"
),
distances AS (
    SELECT
        prev_state,
        prev_city,
        cur_state,
        cur_city,
        ((cur_lat - prev_lat)*(cur_lat - prev_lat) +
         (cur_lng - prev_lng)*(cur_lng - prev_lng)) AS dist2
    FROM ordered
    WHERE prev_lat IS NOT NULL
)
SELECT
    prev_state || ' - ' || prev_city || ' -> ' ||
    cur_state  || ' - ' || cur_city               AS travel_coordinates,
    ROUND(dist2, 4)                               AS cumulative_travel_distance
FROM distances
ORDER BY dist2 DESC
LIMIT 1;