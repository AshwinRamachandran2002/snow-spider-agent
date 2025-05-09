WITH loop_trips AS (      -- 1. trips that start and end at the same station
    SELECT
        "start_station_id",
        "end_station_id",
        "starttime"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "start_station_id" IS NOT NULL
      AND "end_station_id" IS NOT NULL
      AND "start_station_id" = "end_station_id"
), ---------------------------------------------------------------
loop_windows AS (         -- 2. place those trips in 2-minute windows
    SELECT
        *,
        FLOOR("starttime" / 120000000) AS window_slot   -- 120 s × 1 000 000 µs
    FROM loop_trips
), ---------------------------------------------------------------
window_counts AS (        -- 3. count trips per station & window
    SELECT
        "start_station_id"           AS station_id,
        window_slot,
        COUNT(*)                     AS window_trip_cnt
    FROM loop_windows
    GROUP BY station_id, window_slot
), ---------------------------------------------------------------
group_loop_trips AS (     -- 4. keep only trips in windows with >1 trips
    SELECT l.*
    FROM loop_windows  l
    JOIN window_counts w
      ON l."start_station_id" = w.station_id
     AND l.window_slot        = w.window_slot
    WHERE w.window_trip_cnt > 1
), ---------------------------------------------------------------
group_counts AS (         -- 5. number of group-loop trips per station
    SELECT
        "end_station_id"            AS station_id,
        COUNT(*)                    AS group_trip_cnt
    FROM group_loop_trips
    GROUP BY station_id
), ---------------------------------------------------------------
total_counts AS (         -- 6. total trips that END at each station
    SELECT
        "end_station_id"            AS station_id,
        COUNT(*)                    AS total_trip_cnt
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "end_station_id" IS NOT NULL
    GROUP BY station_id
), ---------------------------------------------------------------
proportions AS (          -- 7. compute proportion of group rides
    SELECT
        t.station_id,
        COALESCE(g.group_trip_cnt, 0)                     AS group_trip_cnt,
        t.total_trip_cnt,
        COALESCE(g.group_trip_cnt, 0) / t.total_trip_cnt  AS prop_group
    FROM total_counts t
    LEFT JOIN group_counts g USING (station_id)
) ---------------------------------------------------------------
SELECT
    p.station_id                                    AS "STATION_ID",
    s."name"                                        AS "STATION_NAME",
    p.group_trip_cnt                                AS "GROUP_TRIPS",
    p.total_trip_cnt                                AS "TOTAL_TRIPS",
    ROUND(p.prop_group, 4)                          AS "GROUP_PROPORTION"
FROM proportions           p
LEFT JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS s
       ON TRY_TO_NUMBER(s."station_id") = p.station_id   -- only match numeric IDs
ORDER BY p.prop_group DESC NULLS LAST
LIMIT 10;