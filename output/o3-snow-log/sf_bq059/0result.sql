SELECT 
    ROUND( MAX("distance_m" / "duration_sec"), 1 ) AS "highest_avg_speed_m_per_s"
FROM (
    SELECT  
        "duration_sec",
        ST_DISTANCE(
            TO_GEOGRAPHY('POINT(' || "start_station_longitude" || ' ' || "start_station_latitude" || ')'),
            TO_GEOGRAPHY('POINT(' || "end_station_longitude"   || ' ' || "end_station_latitude"   || ')')
        ) AS "distance_m"
    FROM SAN_FRANCISCO_PLUS.SAN_FRANCISCO_BIKESHARE.BIKESHARE_TRIPS
    WHERE ("start_station_name" ILIKE '%berkeley%' OR "end_station_name" ILIKE '%berkeley%')
      AND "duration_sec" > 0                       -- exclude null/zero durations
) t
WHERE "distance_m" > 1000;                         -- consider trips longer than 1 km