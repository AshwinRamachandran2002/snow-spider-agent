WITH ordered AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_lat" AS lat,
        "geolocation_lng" AS lng,
        LAG("geolocation_state") OVER w AS prev_state,
        LAG("geolocation_city")  OVER w AS prev_city,
        LAG("geolocation_lat")   OVER w AS prev_lat,
        LAG("geolocation_lng")   OVER w AS prev_lng
    FROM "olist_geolocation"
    WINDOW w AS (
        ORDER BY
            "geolocation_state",
            "geolocation_city",
            "geolocation_zip_code_prefix",
            "geolocation_lat",
            "geolocation_lng"
    )
)
SELECT
    prev_state || ' - ' || prev_city          AS "previous_city",
    "geolocation_state" || ' - ' || "geolocation_city" AS "current_city",
    ((lat - prev_lat)*(lat - prev_lat) +
     (lng - prev_lng)*(lng - prev_lng))       AS "distance_squared"
FROM   ordered
WHERE  prev_lat IS NOT NULL
ORDER  BY "distance_squared" DESC
LIMIT 1;