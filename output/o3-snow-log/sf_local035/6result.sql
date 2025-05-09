WITH ordered AS (   -- put all rows in the required ordering and fetch the previous row’s coordinates
    SELECT
        "geolocation_state"                      AS curr_state,
        "geolocation_city"                       AS curr_city,
        "geolocation_zip_code_prefix"            AS curr_zip,
        "geolocation_lat"                        AS curr_lat,
        "geolocation_lng"                        AS curr_lng,

        LAG("geolocation_state") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        )                                        AS prev_state,

        LAG("geolocation_city")  OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        )                                        AS prev_city,

        LAG("geolocation_zip_code_prefix") OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        )                                        AS prev_zip,

        LAG("geolocation_lat")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        )                                        AS prev_lat,

        LAG("geolocation_lng")   OVER (
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        )                                        AS prev_lng
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_GEOLOCATION
    WHERE "geolocation_lat" IS NOT NULL
      AND "geolocation_lng" IS NOT NULL
),

distances AS (      -- compute the great-circle distance to the previous row
    SELECT
        prev_state, prev_city, prev_zip, prev_lat, prev_lng,
        curr_state, curr_city, curr_zip, curr_lat, curr_lng,

        6371 * ACOS(
            LEAST( 1 ,
                   GREATEST(-1 ,
                       COS(RADIANS(prev_lat)) * COS(RADIANS(curr_lat)) *
                       COS(RADIANS(curr_lng) - RADIANS(prev_lng)) +
                       SIN(RADIANS(prev_lat)) * SIN(RADIANS(curr_lat))
                   )
            )
        )                                             AS distance_km
    FROM ordered
    WHERE prev_lat IS NOT NULL
      AND prev_lng IS NOT NULL
)

SELECT
    prev_state  AS city1_state,
    prev_city   AS city1_name,
    prev_zip    AS city1_zip_prefix,
    prev_lat    AS city1_lat,
    prev_lng    AS city1_lng,
    curr_state  AS city2_state,
    curr_city   AS city2_name,
    curr_zip    AS city2_zip_prefix,
    curr_lat    AS city2_lat,
    curr_lng    AS city2_lng,
    distance_km
FROM distances
ORDER BY distance_km DESC NULLS LAST
LIMIT 1;