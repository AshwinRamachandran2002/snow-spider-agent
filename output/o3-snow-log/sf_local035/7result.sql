/*----------------------------------------------------------
  Consecutive-row distance in BRAZILIAN_E_COMMERCE.BRAZILIAN_E_COMMERCE.OLIST_GEOLOCATION
  ----------------------------------------------------------
  1. Order every geolocation row by the required columns and
     give it a sequential row number (rn).

  2. Join each row to its immediate predecessor (rn-1).

  3. Compute the great-circle distance (km) via the Spherical
     Law of Cosines, clamping the inner value to [-1,1] to
     avoid numeric overflow in ACOS.

  4. Return the two consecutive rows with the greatest
     distance between them.
----------------------------------------------------------*/
WITH ordered AS (
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
paired AS (
    SELECT
        o1."geolocation_state" AS state1,
        o1."geolocation_city"  AS city1,
        o1."geolocation_zip_code_prefix" AS zip1,
        o1."geolocation_lat"   AS lat1,
        o1."geolocation_lng"   AS lng1,

        o2."geolocation_state" AS state2,
        o2."geolocation_city"  AS city2,
        o2."geolocation_zip_code_prefix" AS zip2,
        o2."geolocation_lat"   AS lat2,
        o2."geolocation_lng"   AS lng2,

        /* Great-circle distance in kilometres */
        6371 * ACOS(
                 LEAST(
                     1,                           -- upper clamp
                     GREATEST(
                         -1,                      -- lower clamp
                         COS(RADIANS(o1."geolocation_lat"))
                       * COS(RADIANS(o2."geolocation_lat"))
                       * COS(RADIANS(o2."geolocation_lng") - RADIANS(o1."geolocation_lng"))
                       + SIN(RADIANS(o1."geolocation_lat"))
                       * SIN(RADIANS(o2."geolocation_lat"))
                     )
                 )
             ) AS distance_km
    FROM ordered o1
    JOIN ordered o2
      ON o2.rn = o1.rn + 1      -- immediate successor
)
SELECT
    state1        AS first_state,
    city1         AS first_city,
    zip1          AS first_zip_prefix,
    lat1          AS first_lat,
    lng1          AS first_lng,

    state2        AS second_state,
    city2         AS second_city,
    zip2          AS second_zip_prefix,
    lat2          AS second_lat,
    lng2          AS second_lng,

    ROUND(distance_km, 4) AS max_distance_km
FROM paired
ORDER BY distance_km DESC NULLS LAST
LIMIT 1;