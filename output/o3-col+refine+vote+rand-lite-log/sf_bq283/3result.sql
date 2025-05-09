WITH active_stations AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE "status" ILIKE '%active%'
),
total_active_trips AS (
    SELECT COUNT(*) AS "total_trips"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
),
station_stats AS (
    SELECT
        t."start_station_id"                                 AS "station_id",
        COUNT(*)                                             AS "starting_trips",
        AVG(t."duration_minutes")                            AS "avg_duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
ranked AS (
    SELECT
        ss.*,
        RANK() OVER (ORDER BY ss."starting_trips" DESC)      AS "trip_rank"
    FROM station_stats ss
)
SELECT
    r."station_id",
    r."starting_trips",
    ROUND(100.0 * r."starting_trips" / tat."total_trips", 2) AS "pct_of_active_trips",
    ROUND(r."avg_duration_minutes", 2)                       AS "avg_duration_minutes"
FROM ranked r
CROSS JOIN total_active_trips tat
WHERE r."trip_rank" <= 15
ORDER BY r."trip_rank", r."station_id";