WITH valid_data AS (
    SELECT
        *
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_GEOLOCATION"
    WHERE 
        "geolocation_lat" BETWEEN -90 AND 90
        AND "geolocation_lng" BETWEEN -180 AND 180
        AND "geolocation_lat" IS NOT NULL
        AND "geolocation_lng" IS NOT NULL
),
sorted_data AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng",
        LAG("geolocation_state") OVER (
            ORDER BY "geolocation_state", "geolocation_city", "geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"
        ) AS "prev_state",
        LAG("geolocation_city") OVER (
            ORDER BY "geolocation_state", "geolocation_city", "geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"
        ) AS "prev_city",
        LAG("geolocation_zip_code_prefix") OVER (
            ORDER BY "geolocation_state", "geolocation_city", "geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"
        ) AS "prev_zip",
        LAG("geolocation_lat") OVER (
            ORDER BY "geolocation_state", "geolocation_city", "geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"
        ) AS "prev_lat",
        LAG("geolocation_lng") OVER (
            ORDER BY "geolocation_state", "geolocation_city", "geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"
        ) AS "prev_lng"
    FROM valid_data
)
SELECT
    "prev_city" AS "First_City",
    'POINT(' || "prev_lng" || ' ' || "prev_lat" || ')' AS "First_City_Coordinates",
    "geolocation_city" AS "Second_City",
    'POINT(' || "geolocation_lng" || ' ' || "geolocation_lat" || ')' AS "Second_City_Coordinates",
    ROUND(distance_km, 4) AS "Distance_km"
FROM (
    SELECT *,
        6371 * ACOS(
            LEAST(1, GREATEST(-1,
                COS(RADIANS("prev_lat")) * COS(RADIANS("geolocation_lat")) * COS(RADIANS("geolocation_lng") - RADIANS("prev_lng"))
                + SIN(RADIANS("prev_lat")) * SIN(RADIANS("geolocation_lat"))
            ))
        ) AS distance_km
    FROM sorted_data
    WHERE "prev_lat" IS NOT NULL AND "prev_lng" IS NOT NULL
)
ORDER BY distance_km DESC NULLS LAST
LIMIT 1;