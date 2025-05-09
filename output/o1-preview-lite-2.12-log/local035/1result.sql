WITH OrderedLocations AS (
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
)
SELECT
  "geolocation_state",
  "prev_city" AS "geolocation_city_previous",
  "geolocation_city" AS "geolocation_city_current",
  (
    2 * 6371 * ASIN(
      SQRT(
        POWER(SIN( (("geolocation_lat" - "prev_lat") * PI() / 180 / 2) ), 2) +
        COS( "prev_lat" * PI() / 180 ) * COS( "geolocation_lat" * PI() / 180 ) *
        POWER(SIN( (("geolocation_lng" - "prev_lng") * PI() / 180 / 2) ), 2)
      )
    )
  ) AS "distance_km"
FROM OrderedLocations
WHERE "prev_lat" IS NOT NULL
ORDER BY "distance_km" DESC
LIMIT 1;