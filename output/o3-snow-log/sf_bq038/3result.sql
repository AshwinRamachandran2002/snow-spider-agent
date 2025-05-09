WITH trips AS (          -- all rides with valid station ids & start time
    SELECT  CAST("start_station_id" AS NUMBER)         AS start_id ,
            CAST("end_station_id"   AS NUMBER)         AS end_id  ,
            "starttime"                                 AS start_ts
    FROM    NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE   "start_station_id" IS NOT NULL
      AND   "end_station_id"   IS NOT NULL
      AND   "starttime"        IS NOT NULL
),

loops AS (               -- loop-rides: start & end at same station
    SELECT  start_id      AS station_id ,
            start_ts ,
            FLOOR( (start_ts/1000000) / 120 )           AS window_key   -- 2-minute bucket
    FROM    trips
    WHERE   start_id = end_id
),

window_counts AS (       -- windows with 2+ simultaneous loop-rides
    SELECT  station_id ,
            window_key ,
            COUNT(*)     AS rides_in_window
    FROM    loops
    GROUP BY station_id , window_key
    HAVING  COUNT(*) > 1
),

group_ride_trips AS (    -- every trip that belongs to a group ride
    SELECT  l.station_id
    FROM    loops l
    JOIN    window_counts w
           ON l.station_id = w.station_id
          AND l.window_key = w.window_key
),

station_group_counts AS (   -- #group-ride trips per station
    SELECT  station_id ,
            COUNT(*) AS group_trip_cnt
    FROM    group_ride_trips
    GROUP BY station_id
),

station_total_counts AS (   -- total trips ending at each station
    SELECT  CAST("end_station_id" AS NUMBER) AS station_id ,
            COUNT(*)                          AS total_trip_cnt
    FROM    NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE   "end_station_id" IS NOT NULL
    GROUP BY station_id
),

proportions AS (            -- compute proportion
    SELECT  t.station_id ,
            COALESCE(g.group_trip_cnt,0)                        AS group_trip_cnt ,
            t.total_trip_cnt ,
            COALESCE(g.group_trip_cnt,0) / t.total_trip_cnt::FLOAT  AS proportion
    FROM    station_total_counts t
    LEFT JOIN station_group_counts g
           ON t.station_id = g.station_id
)

SELECT  s."name"                           AS station_name ,
        p.station_id ,
        p.group_trip_cnt ,
        p.total_trip_cnt ,
        ROUND(p.proportion , 4)            AS proportion
FROM    proportions p
LEFT JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS s
       ON TRY_TO_NUMBER(s."station_id") = p.station_id
ORDER BY proportion DESC NULLS LAST
LIMIT 10;