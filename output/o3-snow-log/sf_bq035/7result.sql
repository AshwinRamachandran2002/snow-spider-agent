WITH trip_points AS (
    SELECT
        T."bike_number",
        S."latitude"  AS "start_lat",
        S."longitude" AS "start_lon",
        E."latitude"  AS "end_lat",
        E."longitude" AS "end_lon"
    FROM SAN_FRANCISCO.SAN_FRANCISCO."BIKESHARE_TRIPS"     T
    JOIN SAN_FRANCISCO.SAN_FRANCISCO."BIKESHARE_STATIONS"  S
         ON T."start_station_id" = S."station_id"
    JOIN SAN_FRANCISCO.SAN_FRANCISCO."BIKESHARE_STATIONS"  E
         ON T."end_station_id"   = E."station_id"
    WHERE S."latitude"  IS NOT NULL
      AND S."longitude" IS NOT NULL
      AND E."latitude"  IS NOT NULL
      AND E."longitude" IS NOT NULL
)

SELECT
    "bike_number",
    ROUND(
        SUM(
            2 * 6371 * ASIN(
                SQRT(
                    POWER(SIN( (RADIANS("end_lat") - RADIANS("start_lat")) / 2 ), 2) +
                    COS(RADIANS("start_lat")) * COS(RADIANS("end_lat")) *
                    POWER(SIN( (RADIANS("end_lon") - RADIANS("start_lon")) / 2 ), 2)
                )
            )
        ),
        4
    ) AS "total_distance_km"
FROM trip_points
GROUP BY "bike_number"
ORDER BY "total_distance_km" DESC NULLS LAST;