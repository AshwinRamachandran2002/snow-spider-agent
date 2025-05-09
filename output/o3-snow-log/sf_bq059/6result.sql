WITH berkeley_trips AS (
    SELECT
        "duration_sec",
        /* Haversine distance in meters */
        2 * 6371000 * ASIN(
            SQRT(
                POWER(
                    SIN(RADIANS( ("end_station_latitude"  - "start_station_latitude")  / 2.0 )), 2
                ) +
                COS(RADIANS("start_station_latitude")) *
                COS(RADIANS("end_station_latitude")) *
                POWER(
                    SIN(RADIANS( ("end_station_longitude" - "start_station_longitude") / 2.0 )), 2
                )
            )
        ) AS "distance_m"
    FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS"
    WHERE (
            "start_station_name" ILIKE '%berkeley%' OR
            "end_station_name"   ILIKE '%berkeley%'
          )
          AND "duration_sec" > 0            -- ensure non-zero duration
)
SELECT
    ROUND( MAX("distance_m" / "duration_sec"), 1 ) AS "highest_avg_speed_m_per_s"
FROM berkeley_trips
WHERE "distance_m" > 1000;                    -- only consider trips > 1 000 m