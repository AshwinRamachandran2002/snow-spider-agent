WITH trips AS (            --  base citibike trips
    SELECT  "start_station_id" AS start_id ,
            "end_station_id"   AS end_id ,
            "starttime"        AS start_ts          -- micro-seconds since epoch
    FROM    NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE   "end_station_id" IS NOT NULL
),

-- 1. round-trips (start & end at same station)
round_trips AS (
    SELECT  start_id                         AS station_id ,
            FLOOR(start_ts/1000000/120)      AS win_2min   -- 2-minute bucket
    FROM    trips
    WHERE   start_id = end_id
      AND   start_id IS NOT NULL
),

-- 2. windows with ≥2 trips  -> group ride windows
group_windows AS (
    SELECT  station_id , win_2min
    FROM    round_trips
    GROUP BY station_id , win_2min
    HAVING  COUNT(*) >= 2
),

-- 3. every trip that belongs to a group-ride window
group_trips AS (
    SELECT  r.station_id
    FROM    round_trips  r
    JOIN    group_windows g
      ON    r.station_id = g.station_id
     AND    r.win_2min   = g.win_2min
),

-- 4. counts
group_counts AS (
    SELECT  station_id , COUNT(*) AS grp_cnt
    FROM    group_trips
    GROUP BY station_id
),
end_counts AS (
    SELECT  end_id AS station_id , COUNT(*) AS tot_end_cnt
    FROM    trips
    GROUP BY end_id
)

-- 5. final proportions & top-10
SELECT  COALESCE( st."name",
                  'Station ' || g.station_id::STRING )  AS station_name ,
        g.station_id                                   ,
        g.grp_cnt         AS group_trip_count          ,
        e.tot_end_cnt     AS total_ending_trips        ,
        ROUND( g.grp_cnt::FLOAT / e.tot_end_cnt , 4 )  AS proportion
FROM    end_counts   e
JOIN    group_counts g   ON g.station_id = e.station_id
LEFT JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS st
       ON st."station_id" = g.station_id::STRING
ORDER BY proportion DESC NULLS LAST
LIMIT 10;