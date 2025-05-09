WITH ordered_geo AS (
    SELECT
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng",
        ROW_NUMBER() OVER (
            ORDER BY
                "geolocation_state",
                "geolocation_city",
                "geolocation_zip_code_prefix",
                "geolocation_lat",
                "geolocation_lng"
        ) AS rn
    FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_GEOLOCATION"
    WHERE "geolocation_lat" IS NOT NULL
      AND "geolocation_lng" IS NOT NULL
),
pairs AS (
    SELECT
        curr.rn,
        prev."geolocation_state"  AS prev_state,
        prev."geolocation_city"   AS prev_city,
        prev."geolocation_zip_code_prefix" AS prev_zip,
        prev."geolocation_lat"    AS prev_lat,
        prev."geolocation_lng"    AS prev_lng,
        curr."geolocation_state"  AS curr_state,
        curr."geolocation_city"   AS curr_city,
        curr."geolocation_zip_code_prefix" AS curr_zip,
        curr."geolocation_lat"    AS curr_lat,
        curr."geolocation_lng"    AS curr_lng,
        6371 * ACOS(
            LEAST(
                1,
                GREATEST(
                    -1,
                    COS(RADIANS(curr."geolocation_lat")) * COS(RADIANS(prev."geolocation_lat")) *
                    COS(RADIANS(prev."geolocation_lng") - RADIANS(curr."geolocation_lng")) +
                    SIN(RADIANS(curr."geolocation_lat")) * SIN(RADIANS(prev."geolocation_lat"))
                )
            )
        ) AS distance_km
    FROM ordered_geo curr
    JOIN ordered_geo prev
      ON curr.rn = prev.rn + 1           -- immediate predecessor in the ordering
)
SELECT
    prev_state        AS "city1_state",
    prev_city         AS "city1_city",
    prev_zip          AS "city1_zip_prefix",
    prev_lat          AS "city1_lat",
    prev_lng          AS "city1_lng",
    curr_state        AS "city2_state",
    curr_city         AS "city2_city",
    curr_zip          AS "city2_zip_prefix",
    curr_lat          AS "city2_lat",
    curr_lng          AS "city2_lng",
    distance_km       AS "distance_km_between_cities"
FROM pairs
ORDER BY distance_km DESC NULLS LAST
LIMIT 1;