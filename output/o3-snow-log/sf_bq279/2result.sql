WITH trip_stations AS (      -- stations that were used in trips during each year
    /* start-station side */
    SELECT  
        EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("start_time", 6))  AS "year",
        CAST("start_station_id" AS NUMBER)                    AS "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_time" IS NOT NULL
      AND EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("start_time", 6)) IN (2013, 2014)

    UNION ALL

    /* end-station side */
    SELECT  
        EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("start_time", 6))  AS "year",
        CAST("end_station_id" AS NUMBER)                      AS "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_time" IS NOT NULL
      AND EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ("start_time", 6)) IN (2013, 2014)
),  
trip_station_distinct AS (    -- one row per year/station
    SELECT DISTINCT 
           "year",
           "station_id"
    FROM trip_stations
    WHERE "station_id" IS NOT NULL
),  
station_status AS (           -- current status of each station
    SELECT 
        "station_id",
        LOWER("status") AS "status"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
)
SELECT
    d."year",
    COUNT_IF(s."status" = 'active') AS "active_station_count",
    COUNT_IF(s."status" = 'closed') AS "closed_station_count"
FROM trip_station_distinct d
LEFT JOIN station_status s
       ON d."station_id" = s."station_id"
GROUP BY d."year"
ORDER BY d."year";