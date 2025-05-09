SELECT
  "First_City",
  CONCAT('POINT(', ROUND("First_Lng", 4), ' ', ROUND("First_Lat", 4), ')') AS "First_City_Coordinates",
  "Second_City",
  CONCAT('POINT(', ROUND("Second_Lng", 4), ' ', ROUND("Second_Lat", 4), ')') AS "Second_City_Coordinates",
  ROUND("Distance_km", 4) AS "Distance_km"
FROM (
  SELECT
    "geolocation_city" AS "First_City",
    "geolocation_lat" AS "First_Lat",
    "geolocation_lng" AS "First_Lng",
    LAG("geolocation_city") OVER (
      ORDER BY
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng"
    ) AS "Second_City",
    LAG("geolocation_lat") OVER (
      ORDER BY
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng"
    ) AS "Second_Lat",
    LAG("geolocation_lng") OVER (
      ORDER BY
        "geolocation_state",
        "geolocation_city",
        "geolocation_zip_code_prefix",
        "geolocation_lat",
        "geolocation_lng"
    ) AS "Second_Lng",
    6371 * ACOS(
      LEAST(
        1,
        GREATEST(
          -1,
          COS(RADIANS("geolocation_lat")) * COS(RADIANS(LAG("geolocation_lat") OVER (
            ORDER BY
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng"
          ))) *
          COS(RADIANS(LAG("geolocation_lng") OVER (
            ORDER BY
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng"
          )) - RADIANS("geolocation_lng")) +
          SIN(RADIANS("geolocation_lat")) * SIN(RADIANS(LAG("geolocation_lat") OVER (
            ORDER BY
              "geolocation_state",
              "geolocation_city",
              "geolocation_zip_code_prefix",
              "geolocation_lat",
              "geolocation_lng"
          )))
        )
      )
    ) AS "Distance_km"
  FROM BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE."OLIST_GEOLOCATION"
  WHERE
    "geolocation_lat" BETWEEN -35 AND 5 AND
    "geolocation_lng" BETWEEN -75 AND -34
) AS subquery
WHERE "Second_City" IS NOT NULL
ORDER BY "Distance_km" DESC NULLS LAST
LIMIT 1;