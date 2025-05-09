WITH ordered AS (    -- 1) list rows in the exact ordering and keep previous row info
    SELECT
        "geolocation_state"  AS "curr_state",
        "geolocation_city"   AS "curr_city",
        "geolocation_lat"    AS "curr_lat",
        "geolocation_lng"    AS "curr_lng",

        LAG("geolocation_state") OVER(
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_state",

        LAG("geolocation_city") OVER(
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_city",

        LAG("geolocation_lat") OVER(
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_lat",

        LAG("geolocation_lng") OVER(
            ORDER BY "geolocation_state",
                     "geolocation_city",
                     "geolocation_zip_code_prefix",
                     "geolocation_lat",
                     "geolocation_lng"
        ) AS "prev_lng"
    FROM "olist_geolocation"
),
distances AS (        -- 2) compute Euclidean distance to the immediate predecessor
    SELECT
        "curr_state",
        "curr_city",
        "prev_state",
        "prev_city",
        SQRT(
            ("curr_lat" - "prev_lat") * ("curr_lat" - "prev_lat") +
            ("curr_lng" - "prev_lng") * ("curr_lng" - "prev_lng")
        ) AS "eucl_dist"
    FROM ordered
    WHERE "prev_state" IS NOT NULL               -- exclude very first row
)
-- 3) pick the pair with the greatest successive-row distance
SELECT
    "curr_state",
    "curr_city",
    "prev_state",
    "prev_city",
    "eucl_dist" AS "max_successive_distance"
FROM distances
ORDER BY "eucl_dist" DESC
LIMIT 1;