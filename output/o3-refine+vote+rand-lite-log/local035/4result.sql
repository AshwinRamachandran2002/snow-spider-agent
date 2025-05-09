WITH ordered AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat"  AS lat,
        "geolocation_lng"  AS lng,

        LAG("geolocation_state") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")               AS prev_state,

        LAG("geolocation_city")  OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")               AS prev_city,

        LAG("geolocation_lat")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")               AS prev_lat,

        LAG("geolocation_lng")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng")               AS prev_lng
    FROM "olist_geolocation"
),
distances AS (
    /* simple squared‑distance in degree space (no trig / sqrt needed) */
    SELECT
        prev_city          AS city_from,
        prev_state         AS state_from,
        "geolocation_city" AS city_to,
        "geolocation_state"AS state_to,
        ( (lat - prev_lat) * (lat - prev_lat) +
          (lng - prev_lng) * (lng - prev_lng) )       AS distance_metric
    FROM ordered
    WHERE prev_lat IS NOT NULL      -- skip the very first row
)
SELECT
    city_from,
    state_from,
    city_to,
    state_to,
    ROUND(distance_metric, 4) AS max_distance_metric
FROM distances
ORDER BY distance_metric DESC
LIMIT 1;