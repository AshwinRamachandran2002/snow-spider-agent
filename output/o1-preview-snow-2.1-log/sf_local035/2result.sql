WITH city_coords AS (
    SELECT 
        TRIM(LOWER("geolocation_city")) AS "city",
        "geolocation_state" AS "state",
        AVG("geolocation_lat") AS "lat",
        AVG("geolocation_lng") AS "lng"
    FROM 
        "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_GEOLOCATION"
    GROUP BY 
        TRIM(LOWER("geolocation_city")),
        "geolocation_state"
),
adjacents AS (
    SELECT DISTINCT
        g1."geolocation_zip_code_prefix",
        c1."city" AS "City1",
        c1."state" AS "State1",
        c2."city" AS "City2",
        c2."state" AS "State2"
    FROM
        "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_GEOLOCATION" g1
    JOIN
        "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_GEOLOCATION" g2
    ON
        g1."geolocation_zip_code_prefix" = g2."geolocation_zip_code_prefix" AND
        (TRIM(LOWER(g1."geolocation_city")) <> TRIM(LOWER(g2."geolocation_city")) OR g1."geolocation_state" <> g2."geolocation_state")
    JOIN city_coords c1 ON c1."city" = TRIM(LOWER(g1."geolocation_city")) AND c1."state" = g1."geolocation_state"
    JOIN city_coords c2 ON c2."city" = TRIM(LOWER(g2."geolocation_city")) AND c2."state" = g2."geolocation_state"
    WHERE
        (c1."city" || c1."state") < (c2."city" || c2."state")
),
city_pairs AS (
    SELECT
        a."City1",
        a."City2",
        c1."lat" AS "lat1",
        c1."lng" AS "lng1",
        c2."lat" AS "lat2",
        c2."lng" AS "lng2"
    FROM adjacents a
    JOIN city_coords c1 ON a."City1" = c1."city" AND a."State1" = c1."state"
    JOIN city_coords c2 ON a."City2" = c2."city" AND a."State2" = c2."state"
)
SELECT
    "City1",
    "City2",
    ROUND(
        6371 * ACOS(
            COS(RADIANS("lat1")) * COS(RADIANS("lat2")) * 
            COS(RADIANS("lng2") - RADIANS("lng1")) + 
            SIN(RADIANS("lat1")) * SIN(RADIANS("lat2"))
            ), 4
        ) AS "Distance_km"
FROM city_pairs
ORDER BY "Distance_km" DESC NULLS LAST
LIMIT 1;