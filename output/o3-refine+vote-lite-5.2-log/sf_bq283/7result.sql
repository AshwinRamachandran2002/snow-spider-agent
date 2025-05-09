WITH active_stations AS (
    /* all stations whose current status is active */
    SELECT
        "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),
station_trip_stats AS (
    /* trips that START at an active station */
    SELECT
        t."start_station_id"                AS "station_id",
        COUNT(*)                            AS "starting_trip_count",
        AVG(t."duration_minutes")           AS "avg_trip_duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
ranked_stats AS (
    /* rank stations by starting‑trip counts and calculate overall total */
    SELECT
        sts.*,
        SUM(sts."starting_trip_count")  OVER ()                              AS "total_active_start_trips",
        DENSE_RANK()                    OVER (ORDER BY sts."starting_trip_count" DESC) AS "rank"
    FROM station_trip_stats sts
)
SELECT
    "station_id",
    "starting_trip_count",
    ROUND( ("starting_trip_count" / "total_active_start_trips") * 100 , 4)  AS "percentage_of_total_starting_trips",
    ROUND( "avg_trip_duration_minutes", 4)                                   AS "avg_trip_duration_minutes"
FROM ranked_stats
WHERE "rank" <= 15          -- include all ties at the 15th rank
ORDER BY "rank", "station_id";