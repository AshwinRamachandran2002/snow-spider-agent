WITH trips AS (          -- all finished CitiBike trips
    SELECT
        "start_station_id",
        "end_station_id",
        "starttime",
        FLOOR("starttime" / (120 * 1000000))           AS two_min_bucket   -- 2-minute buckets (µs → sec)
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "start_station_id" IS NOT NULL
      AND "end_station_id" IS NOT NULL
),

round_trips AS (         -- riders that start & end at the same station
    SELECT *
    FROM trips
    WHERE "start_station_id" = "end_station_id"
),

group_buckets AS (       -- buckets that contain ≥2 such round-trips
    SELECT
        "start_station_id"      AS station_id,
        two_min_bucket,
        COUNT(*)                AS bucket_trip_cnt
    FROM round_trips
    GROUP BY "start_station_id", two_min_bucket
    HAVING COUNT(*) >= 2
),

group_trips AS (         -- every trip that is part of a “group ride”
    SELECT rt.*
    FROM round_trips rt
    JOIN group_buckets gb
      ON rt."start_station_id" = gb.station_id
     AND rt.two_min_bucket     = gb.two_min_bucket
),

group_counts AS (        -- # of group-ride trips per station (use END station)
    SELECT
        "end_station_id"               AS station_id,
        COUNT(*)                       AS group_trip_cnt
    FROM group_trips
    GROUP BY "end_station_id"
),

total_counts AS (        -- total # of trips ending at each station
    SELECT
        "end_station_id"               AS station_id,
        COUNT(*)                       AS total_trip_cnt
    FROM trips
    GROUP BY "end_station_id"
),

stats AS (               -- compute proportion
    SELECT
        tc.station_id,
        tc.total_trip_cnt,
        COALESCE(gc.group_trip_cnt,0)                  AS group_trip_cnt,
        COALESCE(gc.group_trip_cnt,0)::FLOAT
            / tc.total_trip_cnt                        AS proportion
    FROM total_counts tc
    LEFT JOIN group_counts gc
           ON tc.station_id = gc.station_id
)

SELECT
    cs."name"                                   AS station_name,
    stats.station_id,
    stats.group_trip_cnt,
    stats.total_trip_cnt,
    ROUND(stats.proportion,4)                   AS group_trip_proportion
FROM stats
LEFT JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS cs
       ON cs."station_id" = stats.station_id::TEXT
ORDER BY group_trip_proportion DESC NULLS LAST
LIMIT 10;