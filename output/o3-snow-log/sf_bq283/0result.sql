/* 1. Identify stations whose current status is active.              */
/* 2. Count trips that start at each active station and               */
/*    calculate their average duration.                               */
/* 3. Work out the overall total of starts from active stations       */
/*    to derive each station’s share.                                 */
/* 4. Rank the stations by their trip count and keep the top-15 ranks */
/*    (ties included).                                                */
WITH active_stations AS (
    SELECT
        "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'        -- keep only currently-active stations
),
station_trip_stats AS (
    SELECT
        t."start_station_id"                        AS "station_id",
        COUNT(*)                                    AS "total_start_trips",
        AVG(t."duration_minutes")                   AS "avg_duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
          ON t."start_station_id" = s."station_id"
    GROUP BY
        t."start_station_id"
),
stats_with_share AS (
    SELECT
        sts.*,
        ROUND(
            100.0 * sts."total_start_trips"
            / SUM(sts."total_start_trips") OVER (),   -- overall starts from active stations
            4
        )                                             AS "pct_of_active_starts",
        DENSE_RANK() OVER (ORDER BY sts."total_start_trips" DESC) AS "rank_num"
    FROM station_trip_stats sts
)
SELECT
    "station_id",
    "total_start_trips",
    "pct_of_active_starts",
    ROUND("avg_duration_minutes", 4) AS "avg_duration_minutes"
FROM stats_with_share
WHERE "rank_num" <= 15                -- keep top-15 ranks (ties included)
ORDER BY
    "rank_num",
    "station_id";