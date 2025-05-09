/* Highest average speed (m/s, 1 dp) for Berkeley bike-share trips whose
   straight-line distance exceeds 1 000 m */
SELECT
    ROUND(MAX("avg_speed_m_s"), 1) AS "highest_avg_speed_m_s"
FROM (
    SELECT
        /* straight-line distance in metres (approx.) */
        111111 * SQRT(
            POWER("start_station_latitude" - "end_station_latitude", 2) +
            POWER(
                COS(RADIANS("start_station_latitude"))
                * ("start_station_longitude" - "end_station_longitude"), 2)
        )                     AS "distance_m",
        /* average speed in m/s */
        111111 * SQRT(
            POWER("start_station_latitude" - "end_station_latitude", 2) +
            POWER(
                COS(RADIANS("start_station_latitude"))
                * ("start_station_longitude" - "end_station_longitude"), 2)
        ) / NULLIF("duration_sec", 0) AS "avg_speed_m_s"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE."BIKESHARE_TRIPS"
    WHERE ("start_station_name" ILIKE '%berkeley%'
           OR "end_station_name"   ILIKE '%berkeley%')
      AND "start_station_latitude" IS NOT NULL
      AND "end_station_latitude"   IS NOT NULL
      AND "duration_sec"           > 0
) t
WHERE "distance_m" > 1000;