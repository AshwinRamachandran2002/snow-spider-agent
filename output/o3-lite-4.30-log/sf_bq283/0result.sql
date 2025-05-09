WITH active_stations AS (
    SELECT "station_id"
    FROM "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_STATIONS"
    WHERE "status" = 'active'
),
trip_counts AS (
    SELECT
        t."start_station_id"                      AS "station_id",
        COUNT(*)                                  AS total_starting_trips,
        AVG(t."duration_minutes")                 AS avg_trip_duration_min
    FROM "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_TRIPS" t
    JOIN active_stations a ON t."start_station_id" = a."station_id"
    GROUP BY t."start_station_id"
),
overall AS (
    SELECT SUM(total_starting_trips) AS overall_trips
    FROM trip_counts
),
ranked AS (
    SELECT
        tc."station_id",
        tc.total_starting_trips,
        ROUND(tc.total_starting_trips * 100.0 / o.overall_trips, 4) AS start_trip_pct,
        ROUND(tc.avg_trip_duration_min, 4)                          AS avg_trip_duration_min,
        RANK() OVER (ORDER BY tc.total_starting_trips DESC)         AS station_rank
    FROM trip_counts tc
    CROSS JOIN overall o
)
SELECT
    "station_id",
    total_starting_trips,
    start_trip_pct,
    avg_trip_duration_min
FROM ranked
WHERE station_rank <= 15
ORDER BY station_rank, "station_id";