WITH ordered AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng",
        LAG("geolocation_state") OVER (ORDER BY 
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng") AS "prev_state",
        LAG("geolocation_city")  OVER (ORDER BY 
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng") AS "prev_city",
        LAG("geolocation_zip_code_prefix") OVER (ORDER BY 
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng") AS "prev_zip",
        LAG("geolocation_lat")   OVER (ORDER BY 
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng") AS "prev_lat",
        LAG("geolocation_lng")   OVER (ORDER BY 
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng") AS "prev_lng"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_GEOLOCATION
), distances AS (
    SELECT
        "prev_state",
        "prev_city",
        "prev_zip",
        "geolocation_state"           AS "curr_state",
        "geolocation_city"            AS "curr_city",
        "geolocation_zip_code_prefix" AS "curr_zip",
        6371 * ACOS(
            LEAST(
                1,
                GREATEST(
                    -1,
                    COS(RADIANS("prev_lat")) * COS(RADIANS("geolocation_lat")) *
                    COS(RADIANS("geolocation_lng") - RADIANS("prev_lng")) +
                    SIN(RADIANS("prev_lat")) * SIN(RADIANS("geolocation_lat"))
                )
            )
        ) AS "distance_km"
    FROM ordered
    WHERE "prev_lat" IS NOT NULL
      AND "prev_lng" IS NOT NULL
)
SELECT
    "prev_state" AS previous_state,
    "prev_city"  AS previous_city,
    "prev_zip"   AS previous_zip_code_prefix,
    "curr_state" AS current_state,
    "curr_city"  AS current_city,
    "curr_zip"   AS current_zip_code_prefix,
    ROUND("distance_km", 4) AS max_distance_km
FROM distances
ORDER BY "distance_km" DESC NULLS LAST
LIMIT 1;