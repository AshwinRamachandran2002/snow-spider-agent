WITH same_station_trips AS (   /* trips that start and finish at the same station */
    SELECT
        "start_station_id"    AS station_id,
        "start_station_name"  AS station_name,
        "starttime",
        FLOOR("starttime" / 120000000) AS two_min_window        /* 2-minute bucket (120 000 000 µs) */
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "start_station_id" IS NOT NULL
      AND "end_station_id"   IS NOT NULL
      AND "start_station_id" = "end_station_id"
),

group_windows AS (            /* 2-minute windows that contain at least 2 trips  */
    SELECT
        station_id,
        two_min_window,
        COUNT(*) AS trips_in_window
    FROM same_station_trips
    GROUP BY station_id, two_min_window
    HAVING COUNT(*) >= 2                      /* defines a “group ride” window  */
),

group_trips AS (              /* every trip that belongs to such a window        */
    SELECT
        s.station_id,
        s.station_name
    FROM same_station_trips s
    JOIN group_windows g
      ON s.station_id    = g.station_id
     AND s.two_min_window = g.two_min_window
),

group_counts AS (             /* number of group-ride trips per station          */
    SELECT
        station_id,
        MAX(station_name) AS station_name,
        COUNT(*)          AS group_trip_count
    FROM group_trips
    GROUP BY station_id
),

total_end_trips AS (          /* total trips that end at each station            */
    SELECT
        "end_station_id"   AS station_id,
        MAX("end_station_name") AS station_name,
        COUNT(*)           AS total_end_trip_count
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "end_station_id" IS NOT NULL
    GROUP BY "end_station_id"
),

station_proportions AS (      /* join and compute proportion                     */
    SELECT
        t.station_id,
        COALESCE(g.station_name, t.station_name)              AS station_name,
        COALESCE(g.group_trip_count, 0)                       AS group_trip_count,
        t.total_end_trip_count,
        COALESCE(g.group_trip_count, 0) / t.total_end_trip_count :: FLOAT
            AS group_trip_proportion
    FROM total_end_trips t
    LEFT JOIN group_counts g
      ON t.station_id = g.station_id
)

SELECT
    station_id             AS "station_id",
    station_name           AS "station_name",
    group_trip_count       AS "group_trip_count",
    total_end_trip_count   AS "total_end_trip_count",
    ROUND(group_trip_proportion, 4) AS "group_trip_proportion"
FROM station_proportions
ORDER BY group_trip_proportion DESC NULLS LAST
LIMIT 10;