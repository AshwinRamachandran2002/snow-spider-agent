SELECT ROUND(MAX("speed_m_s"), 4) AS "highest_average_speed_m_s"
FROM (
    SELECT
        ("distance_meters" / t."duration_sec") AS "speed_m_s"
    FROM (
        SELECT
            t."duration_sec",
            ST_DISTANCE(
                ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude"),
                ST_MAKEPOINT(t."end_station_longitude", t."end_station_latitude")
            ) AS "distance_meters"
        FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_TRIPS" t
        WHERE t."duration_sec" > 0
          AND (
                t."start_station_id" IN (
                    SELECT "station_id"
                    FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO"
                    WHERE "region_id" = 14
                )
                OR
                t."end_station_id" IN (
                    SELECT "station_id"
                    FROM "SAN_FRANCISCO_PLUS"."SAN_FRANCISCO_BIKESHARE"."BIKESHARE_STATION_INFO"
                    WHERE "region_id" = 14
                )
            )
    ) t
    WHERE "distance_meters" > 1000
) ;