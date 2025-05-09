WITH city_centroids AS (
    /* one representative point (centroid) for every city              */
    SELECT
        "geolocation_state",
        "geolocation_city",
        MIN("geolocation_zip_code_prefix")               AS "geolocation_zip_code_prefix",
        AVG("geolocation_lat")                           AS "avg_lat",
        AVG("geolocation_lng")                           AS "avg_lng"
    FROM   "olist_geolocation"
    GROUP  BY "geolocation_state", "geolocation_city"
),
lagged AS (
    /* attach the immediately-preceding city in the requested ordering */
    SELECT
        *,
        LAG("geolocation_state") OVER (ORDER BY "geolocation_state",
                                                 "geolocation_city",
                                                 "geolocation_zip_code_prefix",
                                                 "avg_lat",
                                                 "avg_lng") AS "prev_state",
        LAG("geolocation_city")  OVER (ORDER BY "geolocation_state",
                                                 "geolocation_city",
                                                 "geolocation_zip_code_prefix",
                                                 "avg_lat",
                                                 "avg_lng") AS "prev_city",
        LAG("avg_lat")           OVER (ORDER BY "geolocation_state",
                                                 "geolocation_city",
                                                 "geolocation_zip_code_prefix",
                                                 "avg_lat",
                                                 "avg_lng") AS "prev_lat",
        LAG("avg_lng")           OVER (ORDER BY "geolocation_state",
                                                 "geolocation_city",
                                                 "geolocation_zip_code_prefix",
                                                 "avg_lat",
                                                 "avg_lng") AS "prev_lng"
    FROM city_centroids
),
distances AS (
    /* great-circle (Haversine) distance between current & previous    */
    SELECT
        "prev_state"  AS "first_city_state",
        "prev_city"   AS "first_city_name",
        "geolocation_state" AS "second_city_state",
        "geolocation_city"  AS "second_city_name",
        6371.0 * ACOS(
              COS(RADIANS("avg_lat")) * COS(RADIANS("prev_lat")) *
              COS(RADIANS("prev_lng" - "avg_lng")) +
              SIN(RADIANS("avg_lat")) * SIN(RADIANS("prev_lat"))
        )                                                AS "distance_km"
    FROM   lagged
    WHERE  "prev_lat" IS NOT NULL
)
SELECT
    "first_city_state",
    "first_city_name",
    "second_city_state",
    "second_city_name",
    ROUND("distance_km",4) AS "distance_km"
FROM   distances
ORDER  BY "distance_km" DESC
LIMIT 1;