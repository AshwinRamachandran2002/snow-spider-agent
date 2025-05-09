WITH trips AS (
    /* all trips with valid station ids & start time */
    SELECT  
        CAST("start_station_id" AS NUMBER)  AS start_id ,
        CAST("end_station_id"   AS NUMBER)  AS end_id   ,
        "starttime"                         AS start_ts
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "start_station_id" IS NOT NULL
      AND "end_station_id"   IS NOT NULL
      AND "starttime"        IS NOT NULL
), ------------------------------------------------------------------
round_trips AS (
    /* candidate trips: round-trips that start & end at same station   */
    SELECT  
        start_id                                   AS station_id ,
        FLOOR(start_ts / 120000000)                AS time_window   -- 120 s in µs
    FROM trips
    WHERE start_id = end_id                       -- round-trip
), ------------------------------------------------------------------
group_windows AS (
    /* 2-minute windows having ≥2 such trips (i.e. a “group ride” window) */
    SELECT  
        station_id ,
        time_window ,
        COUNT(*) AS trips_in_window
    FROM round_trips
    GROUP BY station_id , time_window
    HAVING COUNT(*) >= 2
), ------------------------------------------------------------------
group_trip_counts AS (
    /* number of individual trips that belong to any qualifying window */
    SELECT  
        rt.station_id ,
        COUNT(*) AS group_trip_cnt
    FROM round_trips rt
    JOIN group_windows gw
      ON rt.station_id = gw.station_id
     AND rt.time_window = gw.time_window
    GROUP BY rt.station_id
), ------------------------------------------------------------------
total_trip_counts AS (
    /* all trips that END at the station (denominator) */
    SELECT  
        CAST("end_station_id" AS NUMBER) AS station_id ,
        COUNT(*)               AS total_trip_cnt
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "end_station_id" IS NOT NULL
    GROUP BY CAST("end_station_id" AS NUMBER)
), ------------------------------------------------------------------
proportions AS (
    SELECT  
        t.station_id ,
        g.group_trip_cnt ,
        t.total_trip_cnt ,
        g.group_trip_cnt::FLOAT / t.total_trip_cnt AS proportion
    FROM total_trip_counts t
    JOIN group_trip_counts g
      ON t.station_id = g.station_id
) ------------------------------------------------------------------
SELECT  
    COALESCE(s."name",'UNKNOWN')                          AS station_name ,
    p.station_id ,
    p.group_trip_cnt ,
    p.total_trip_cnt ,
    ROUND(p.proportion , 4)                               AS group_trip_proportion
FROM proportions p
LEFT JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS s
       ON TRY_TO_NUMBER(s."station_id") = p.station_id
ORDER BY group_trip_proportion DESC NULLS LAST
LIMIT 10;