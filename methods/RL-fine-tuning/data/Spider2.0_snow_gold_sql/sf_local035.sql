WITH valid_data AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        CAST("geolocation_lat" AS FLOAT) AS "geolocation_lat",
        CAST("geolocation_lng" AS FLOAT) AS "geolocation_lng"
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_GEOLOCATION"
    WHERE 
        "geolocation_lat" BETWEEN -34 AND 6
        AND "geolocation_lng" BETWEEN -74 AND -34
),
sorted_data AS (
    SELECT
        *,
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
),
distances AS (
    SELECT
        "prev_city" AS "First_City",
        'POINT(' || "prev_lng" || ' ' || "prev_lat" || ')' AS "First_City_Coordinates",
        "geolocation_city" AS "Second_City",
        'POINT(' || "geolocation_lng" || ' ' || "geolocation_lat" || ')' AS "Second_City_Coordinates",
        ROUND(6371 * ACOS(
                LEAST(1, GREATEST(-1, 
                    COS(RADIANS("prev_lat")) * COS(RADIANS("geolocation_lat")) * 
                    COS(RADIANS("geolocation_lng") - RADIANS("prev_lng")) +
                    SIN(RADIANS("prev_lat")) * SIN(RADIANS("geolocation_lat"))
                ))
            ), 4) AS "Distance_km"
    FROM sorted_data
    WHERE "prev_lat" IS NOT NULL
      AND "prev_lng" IS NOT NULL
      AND ("geolocation_city" <> "prev_city" OR "geolocation_state" <> "prev_state")
)
SELECT
    "First_City",
    "First_City_Coordinates",
    "Second_City",
    "Second_City_Coordinates",
    "Distance_km"
FROM distances
ORDER BY "Distance_km" DESC NULLS LAST
LIMIT 1;