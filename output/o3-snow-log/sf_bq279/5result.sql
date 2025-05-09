/* 1)  Collect every station that recorded at least one trip during 2013 or 2014
       (either as a start or an end station).                                       */
WITH trip_year_station AS (
        /* Start-station side */
        SELECT  TO_NUMBER(TO_CHAR(TO_TIMESTAMP_NTZ("start_time"/1000000),'YYYY')) AS "year",
                "start_station_id"::NUMBER                                         AS "station_id"
        FROM    AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
        WHERE   "start_station_id" IS NOT NULL
          AND   TO_NUMBER(TO_CHAR(TO_TIMESTAMP_NTZ("start_time"/1000000),'YYYY')) IN (2013,2014)

        UNION                                  -- include end-station side
        SELECT  TO_NUMBER(TO_CHAR(TO_TIMESTAMP_NTZ("start_time"/1000000),'YYYY')) AS "year",
                "end_station_id"::NUMBER                                           AS "station_id"
        FROM    AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
        WHERE   "end_station_id"   IS NOT NULL
          AND   TO_NUMBER(TO_CHAR(TO_TIMESTAMP_NTZ("start_time"/1000000),'YYYY')) IN (2013,2014)
)

/* 2)  Join to the stations table to obtain the current status,
       then count distinct stations by year & status.                              */
SELECT  tys."year",
        COALESCE(st."status",'unknown')  AS "station_status",
        COUNT(DISTINCT tys."station_id") AS "distinct_station_count"
FROM    trip_year_station                             tys
LEFT JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS  st
       ON  tys."station_id" = st."station_id"
GROUP BY tys."year", COALESCE(st."status",'unknown')
ORDER BY tys."year" ASC, "station_status";