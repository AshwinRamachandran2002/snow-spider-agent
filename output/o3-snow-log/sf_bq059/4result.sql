WITH berkeley_trips AS (
    SELECT
        ST_DISTANCE(
            ST_POINT("start_station_longitude", "start_station_latitude"),
            ST_POINT("end_station_longitude",   "end_station_latitude")
        ) / NULLIF("duration_sec", 0)                AS "avg_speed_m_per_s"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE ("start_station_name" ILIKE '%Berkeley%'
        OR "end_station_name"   ILIKE '%Berkeley%')
      AND "duration_sec" > 0
      AND ST_DISTANCE(
            ST_POINT("start_station_longitude", "start_station_latitude"),
            ST_POINT("end_station_longitude",   "end_station_latitude")
          ) > 1000
)
SELECT ROUND(MAX("avg_speed_m_per_s"), 1) AS "max_avg_speed_m_per_s"
FROM berkeley_trips;