WITH ordered_geolocations AS (
    SELECT
        *,
        ROW_NUMBER() OVER (
            ORDER BY
                "geolocation_state",
                "geolocation_city",
                "geolocation_zip_code_prefix",
                "geolocation_lat",
                "geolocation_lng"
            ) AS rn
    FROM "olist_geolocation"
),
geolocations_with_prev AS (
    SELECT
        curr."geolocation_state",
        prev."geolocation_city" AS "geolocation_city_previous",
        curr."geolocation_city" AS "geolocation_city_current",
        curr."geolocation_lat" AS lat_curr,
        curr."geolocation_lng" AS lng_curr,
        prev."geolocation_lat" AS lat_prev,
        prev."geolocation_lng" AS lng_prev
    FROM ordered_geolocations curr
    JOIN ordered_geolocations prev
        ON curr.rn = prev.rn + 1
),
distances AS (
    SELECT
        "geolocation_state",
        "geolocation_city_previous",
        "geolocation_city_current",
        6371 * 2 * ASIN(
            SQRT(
                POWER(SIN(RADIANS((lat_curr - lat_prev) / 2)), 2) +
                COS(RADIANS(lat_prev)) *
                COS(RADIANS(lat_curr)) *
                POWER(SIN(RADIANS((lng_curr - lng_prev) / 2)), 2)
            )
        ) AS distance_km
    FROM geolocations_with_prev
)
SELECT
    "geolocation_state",
    "geolocation_city_previous",
    "geolocation_city_current",
    ROUND(distance_km, 4) AS distance_km
FROM distances
ORDER BY distance_km DESC
LIMIT 1;