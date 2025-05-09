WITH loops AS (          -- trips that start AND end at the same station
    SELECT 
        "start_station_id" AS "station_id",
        "starttime"        AS "start_time"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "start_station_id" IS NOT NULL
      AND "start_station_id" = "end_station_id"
),
windows AS (             -- 2-minute buckets (120 s = 120 000 000 µs)
    SELECT
        "station_id",
        FLOOR("start_time" / 120000000) AS "bucket"
    FROM loops
),
group_buckets AS (       -- buckets that contain ≥2 trips  → group-ride bucket
    SELECT
        "station_id",
        "bucket"
    FROM windows
    GROUP BY "station_id", "bucket"
    HAVING COUNT(*) >= 2
),
group_trips AS (         -- every trip that is part of a group ride
    SELECT w."station_id"
    FROM windows w
    JOIN group_buckets g
      ON w."station_id" = g."station_id"
     AND w."bucket"     = g."bucket"
),
group_cnt AS (           -- number of group-ride trips per station
    SELECT
        "station_id",
        COUNT(*) AS "grp_trips"
    FROM group_trips
    GROUP BY "station_id"
),
total_cnt AS (           -- total trips that END at each station
    SELECT
        "end_station_id" AS "station_id",
        COUNT(*)         AS "tot_trips"
    FROM NEW_YORK.NEW_YORK.CITIBIKE_TRIPS
    WHERE "end_station_id" IS NOT NULL
    GROUP BY "end_station_id"
),
proportions AS (         -- combine & compute proportion
    SELECT
        t."station_id",
        COALESCE(g."grp_trips", 0)                       AS "grp_trips",
        t."tot_trips",
        COALESCE(g."grp_trips", 0) / t."tot_trips"::FLOAT AS "prop"
    FROM total_cnt t
    LEFT JOIN group_cnt g
           ON t."station_id" = g."station_id"
)
SELECT
    s."name"                    AS "station_name",
    p."station_id",
    p."grp_trips",
    p."tot_trips",
    ROUND(p."prop", 4)          AS "group_ride_proportion"
FROM proportions p
JOIN NEW_YORK.NEW_YORK.CITIBIKE_STATIONS s
      ON TRY_TO_NUMBER(s."station_id") = p."station_id"
ORDER BY
    "group_ride_proportion" DESC NULLS LAST
LIMIT 10;