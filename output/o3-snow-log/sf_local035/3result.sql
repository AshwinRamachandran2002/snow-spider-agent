/*  Greatest distance between consecutive cities
    (ordered by state, city, zip, lat, lng)            */
WITH ordered AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng",
        
        /* previous row in the specified ordering */
        LAG("geolocation_state") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_state,
        LAG("geolocation_city")  OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_city,
        LAG("geolocation_lat")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_lat,
        LAG("geolocation_lng")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS prev_lng
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_GEOLOCATION
    WHERE "geolocation_lat" IS NOT NULL
      AND "geolocation_lng" IS NOT NULL
),

distance_calc AS (
    SELECT
        prev_state           AS "PREVIOUS_STATE",
        prev_city            AS "PREVIOUS_CITY",
        "geolocation_state"  AS "CURRENT_STATE",
        "geolocation_city"   AS "CURRENT_CITY",
        
        /* distance in km – clamp cosine term to [-1,1] to avoid domain errors */
        6371 * ACOS(
            LEAST(
                1,
                GREATEST(
                    -1,
                      COS(RADIANS(prev_lat)) * COS(RADIANS("geolocation_lat"))
                    * COS(RADIANS("geolocation_lng") - RADIANS(prev_lng))
                    + SIN(RADIANS(prev_lat)) * SIN(RADIANS("geolocation_lat"))
                )
            )
        ) AS "DISTANCE_KM"
    FROM ordered
    WHERE prev_lat IS NOT NULL
      AND prev_lng IS NOT NULL
)

SELECT *
FROM distance_calc
ORDER BY "DISTANCE_KM" DESC NULLS LAST
LIMIT 1;