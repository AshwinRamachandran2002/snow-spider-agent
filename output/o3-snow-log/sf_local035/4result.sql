WITH ordered AS (   -- 1. put every row in the required ordering and bring the previous row’s data with LAG
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng",
        LAG("geolocation_state")  OVER (ORDER BY "geolocation_state",
                                                "geolocation_city",
                                                "geolocation_zip_code_prefix",
                                                "geolocation_lat",
                                                "geolocation_lng")                                    AS prev_state,
        LAG("geolocation_city")   OVER (ORDER BY "geolocation_state",
                                                "geolocation_city",
                                                "geolocation_zip_code_prefix",
                                                "geolocation_lat",
                                                "geolocation_lng")                                    AS prev_city,
        LAG("geolocation_zip_code_prefix") OVER (ORDER BY "geolocation_state",
                                                         "geolocation_city",
                                                         "geolocation_zip_code_prefix",
                                                         "geolocation_lat",
                                                         "geolocation_lng")                           AS prev_zip,
        LAG("geolocation_lat")    OVER (ORDER BY "geolocation_state",
                                                "geolocation_city",
                                                "geolocation_zip_code_prefix",
                                                "geolocation_lat",
                                                "geolocation_lng")                                    AS prev_lat,
        LAG("geolocation_lng")    OVER (ORDER BY "geolocation_state",
                                                "geolocation_city",
                                                "geolocation_zip_code_prefix",
                                                "geolocation_lat",
                                                "geolocation_lng")                                    AS prev_lng
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_GEOLOCATION
),

distances AS (       -- 2. calculate distance (in kilometres) to the previous row
    SELECT
        *,
        6371 * ACOS(      -- spherical law of cosines
              LEAST(1.0, GREATEST(-1.0,      -- clamp to avoid numeric overflow in ACOS
                    COS(RADIANS(prev_lat)) * COS(RADIANS("geolocation_lat"))
                  * COS(RADIANS("geolocation_lng") - RADIANS(prev_lng))
                  + SIN(RADIANS(prev_lat)) * SIN(RADIANS("geolocation_lat"))
              ))
        ) AS distance_km
    FROM ordered
    WHERE prev_lat IS NOT NULL              -- skip the very first row (no predecessor)
)

-- 3. pick the pair with the greatest distance
SELECT
    prev_state           AS previous_state,
    prev_city            AS previous_city,
    prev_zip             AS previous_zip_prefix,
    prev_lat             AS previous_lat,
    prev_lng             AS previous_lng,
    "geolocation_state"  AS current_state,
    "geolocation_city"   AS current_city,
    "geolocation_zip_code_prefix" AS current_zip_prefix,
    "geolocation_lat"    AS current_lat,
    "geolocation_lng"    AS current_lng,
    distance_km
FROM distances
ORDER BY distance_km DESC NULLS LAST
LIMIT 1;