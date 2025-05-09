/*  Chicago center: 41.8319°N , -87.6847°W                                         */
/*  Haversine distance (km) = 2 * R * asin( sqrt( … ) ),  R ≈ 6 371 km            */
WITH stations_with_distance AS (
    SELECT
        "id",
        "name",
        "latitude",
        "longitude",
        2 * 6371 * ASIN(
              SQRT(
                  POWER(SIN( (RADIANS("latitude"  - 41.8319)) / 2 ), 2) +
                  COS(RADIANS(41.8319)) * COS(RADIANS("latitude")) *
                  POWER(SIN( (RADIANS("longitude" + 87.6847)) / 2 ), 2)
              )
        )                           AS "distance_km"
    FROM GHCN_D.GHCN_D.GHCND_STATIONS
)
SELECT
    "id",
    "name",
    ROUND("distance_km", 2) AS "distance_km"
FROM stations_with_distance
WHERE "distance_km" <= 50
ORDER BY "distance_km" ASC NULLS LAST;