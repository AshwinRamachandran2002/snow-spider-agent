WITH ordered_locations AS (
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
    LAG("geolocation_lat") OVER (
      ORDER BY "geolocation_state", "geolocation_city", "geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"
    ) AS "prev_lat",
    LAG("geolocation_lng") OVER (
      ORDER BY "geolocation_state", "geolocation_city", "geolocation_zip_code_prefix", "geolocation_lat", "geolocation_lng"
    ) AS "prev_lng"
  FROM "olist_geolocation"
),
distances AS (
  SELECT
    "geolocation_state",
    "prev_city",
    "geolocation_city",
    CASE
      WHEN "prev_lat" IS NOT NULL AND "geolocation_city" != "prev_city" THEN
        6371 * 2 * asin(
          sqrt(
            POWER(sin((("geolocation_lat" - "prev_lat") * 3.141592653589793 / 180 / 2)), 2) +
            cos("geolocation_lat" * 3.141592653589793 / 180) * cos("prev_lat" * 3.141592653589793 / 180) *
            POWER(sin((("geolocation_lng" - "prev_lng") * 3.141592653589793 / 180 / 2)), 2)
          )
        )
      ELSE 0
    END AS "distance_km"
  FROM ordered_locations
)
SELECT
  "geolocation_state",
  "prev_city" AS "geolocation_city_previous",
  "geolocation_city" AS "geolocation_city_current",
  ROUND("distance_km", 4) AS "distance_km"
FROM distances
WHERE "distance_km" > 0
ORDER BY "distance_km" DESC
LIMIT 1;