WITH active_stations AS (
    -- all stations whose current status is active
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),
station_trip_stats AS (
    -- trip count and average duration for every active start-station
    SELECT
        t."start_station_id"         AS "station_id",
        COUNT(*)                     AS "trip_count",
        AVG(t."duration_minutes")    AS "avg_duration"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
          ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
overall_totals AS (
    SELECT SUM("trip_count") AS "total_trips"
    FROM station_trip_stats
),
ranked AS (
    SELECT
        sts."station_id",
        sts."trip_count",
        ROUND( (sts."trip_count" * 100.0) / ot."total_trips", 4) AS "trip_percentage",
        ROUND(sts."avg_duration", 4)                             AS "avg_duration",
        DENSE_RANK() OVER (ORDER BY sts."trip_count" DESC)       AS "rnk"
    FROM station_trip_stats sts
    CROSS JOIN overall_totals ot
)
SELECT
    "station_id",
    "trip_count",
    "trip_percentage",
    "avg_duration"
FROM ranked
WHERE "rnk" <= 15        -- keep top 15 ranks (ties included)
ORDER BY "rnk", "station_id";