WITH all_trips AS (   -- keep only trips with valid station ids
    SELECT  
        "start_station_id",
        "end_station_id",
        ("starttime" / 1000000)        AS start_ts_sec      -- convert µs → seconds
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "start_station_id" IS NOT NULL
      AND "end_station_id"   IS NOT NULL
), same_station AS (   -- trips that start and end at the same station
    SELECT *,
           FLOOR(start_ts_sec / 120)   AS window_bin        -- 2-minute bin
    FROM all_trips
    WHERE "start_station_id" = "end_station_id"
), cluster_counts AS ( -- 2-minute clusters that have 2+ trips  ⇒ group rides
    SELECT 
        "start_station_id" AS station_id,
        window_bin,
        COUNT(*)           AS trip_cnt
    FROM same_station
    GROUP BY station_id, window_bin
    HAVING COUNT(*) >= 2
), group_trips AS (    -- every trip that belongs to a qualifying cluster
    SELECT s.*
    FROM   same_station s
    JOIN   cluster_counts c
           ON  s."start_station_id" = c.station_id
           AND s.window_bin         = c.window_bin
), group_counts AS (   -- # group-ride trips ending at each station
    SELECT 
        "end_station_id" AS station_id,
        COUNT(*)         AS group_trip_cnt
    FROM group_trips
    GROUP BY "end_station_id"
), total_counts AS (   -- total trips ending at each station
    SELECT 
        "end_station_id" AS station_id,
        COUNT(*)         AS total_trip_cnt
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "end_station_id" IS NOT NULL
    GROUP BY "end_station_id"
), proportions AS (    -- combine and compute proportion
    SELECT
        t.station_id,
        COALESCE(g.group_trip_cnt,0)                 AS group_trip_cnt,
        t.total_trip_cnt,
        COALESCE(g.group_trip_cnt,0)*1.0 / t.total_trip_cnt AS proportion
    FROM total_counts t
    LEFT JOIN group_counts g
           ON t.station_id = g.station_id
)
SELECT 
    p.station_id                            AS "STATION_ID",
    s."name"                                AS "STATION_NAME",
    p.group_trip_cnt                        AS "GROUP_TRIPS",
    p.total_trip_cnt                        AS "TOTAL_TRIPS",
    ROUND(p.proportion,4)                   AS "GROUP_PROPORTION"
FROM proportions p
JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS s
     ON s."station_id" = p.station_id::TEXT
ORDER BY p.proportion DESC NULLS LAST
LIMIT 10;