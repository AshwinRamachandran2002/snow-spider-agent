WITH city_coords AS (
    SELECT "geolocation_city",
           AVG("geolocation_lat") AS "lat",
           AVG("geolocation_lng" ) AS "lng"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_GEOLOCATION"
    WHERE "geolocation_lat" IS NOT NULL AND "geolocation_lng" IS NOT NULL
    GROUP BY "geolocation_city"
),
adjacent_cities AS (
    SELECT DISTINCT a."geolocation_city" AS "City1",
                    b."geolocation_city" AS "City2"
    FROM "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_GEOLOCATION" a
    JOIN "BRAZILIAN_E_COMMERCE"."BRAZILIAN_E_COMMERCE"."OLIST_GEOLOCATION" b
      ON a."geolocation_zip_code_prefix" = b."geolocation_zip_code_prefix"
     AND a."geolocation_city" <> b."geolocation_city"
),
city_pairs AS (
    SELECT ac."City1", ac."City2",
           c1."lat" AS "lat1", c1."lng" AS "lng1",
           c2."lat" AS "lat2", c2."lng" AS "lng2"
    FROM adjacent_cities ac
    JOIN city_coords c1 ON ac."City1" = c1."geolocation_city"
    JOIN city_coords c2 ON ac."City2" = c2."geolocation_city"
),
distances AS (
    SELECT "City1", "City2",
           6371 * ACOS(
               COS(RADIANS("lat1")) * COS(RADIANS("lat2")) * COS(RADIANS("lng2") - RADIANS("lng1")) +
               SIN(RADIANS("lat1")) * SIN(RADIANS("lat2"))
           ) AS "Distance_km"
    FROM city_pairs
),
ordered_distances AS (
    SELECT "City1", "City2", ROUND("Distance_km", 4) AS "Distance_km",
           ROW_NUMBER() OVER (ORDER BY "Distance_km" DESC NULLS LAST) AS rn
    FROM distances
)
SELECT "City1", "City2", "Distance_km"
FROM ordered_distances
WHERE rn = 1;