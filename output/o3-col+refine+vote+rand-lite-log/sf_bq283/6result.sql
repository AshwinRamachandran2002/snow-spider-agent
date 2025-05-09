WITH active_station_ids AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE "status" ILIKE '%active%'
),
active_trips AS (
    SELECT
        "start_station_id",
        COUNT(*)                                      AS "trip_count",
        AVG("duration_minutes")                       AS "avg_duration"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_station_id" IN (SELECT "station_id" FROM active_station_ids)
    GROUP BY "start_station_id"
),
total_active AS (
    SELECT COUNT(*) AS "total_trips"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
    WHERE "start_station_id" IN (SELECT "station_id" FROM active_station_ids)
),
ranked AS (
    SELECT
        at."start_station_id",
        at."trip_count",
        at."avg_duration",
        ROUND((at."trip_count" / total_active."total_trips"::FLOAT) * 100, 4) AS "trip_percentage",
        RANK() OVER (ORDER BY at."trip_count" DESC)                            AS "trip_rank"
    FROM active_trips at, total_active
)
SELECT
    "start_station_id"                       AS "station_id",
    "trip_count",
    "trip_percentage",
    ROUND("avg_duration", 4)                 AS "avg_duration"
FROM ranked
WHERE "trip_rank" <= 15
ORDER BY "trip_rank", "station_id";