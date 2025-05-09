WITH ordered AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_lat",
        "geolocation_lng",
        LAG("geolocation_state") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_state",
        LAG("geolocation_city")  OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_city",
        LAG("geolocation_lat")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_lat",
        LAG("geolocation_lng")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_lng"
    FROM "olist_geolocation"
)
SELECT
    "prev_city"             AS "city_a",
    "geolocation_city"      AS "city_b",
    "prev_state"            AS "state_a",
    "geolocation_state"     AS "state_b",
    111.32 * SQRT(
          POWER("geolocation_lat" - "prev_lat", 2)
        + POWER( ("geolocation_lng" - "prev_lng")
               * COS( (("geolocation_lat" + "prev_lat") / 2.0) * PI() / 180.0 ), 2 )
    )                       AS "distance_km"
FROM ordered
WHERE "prev_lat" IS NOT NULL
ORDER BY "distance_km" DESC
LIMIT 1;