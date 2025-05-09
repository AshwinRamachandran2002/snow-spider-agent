WITH active_stations AS (
    SELECT "station_id"
    FROM "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_STATIONS"
    WHERE LOWER("status") = 'active'
),
station_stats AS (
    SELECT
        t."start_station_id"  AS "station_id",
        COUNT(*)              AS "total_starting_trips",
        AVG(t."duration_minutes") AS "avg_trip_duration_min"
    FROM "AUSTIN"."AUSTIN_BIKESHARE"."BIKESHARE_TRIPS" t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
overall AS (
    SELECT SUM("total_starting_trips") AS "overall_trips"
    FROM station_stats
),
ranked AS (
    SELECT
        ss.*,
        DENSE_RANK() OVER (ORDER BY ss."total_starting_trips" DESC) AS "rk"
    FROM station_stats ss
)
SELECT
    r."station_id",
    r."total_starting_trips",
    ROUND(r."total_starting_trips" * 100.0 / o."overall_trips", 4) AS "start_trip_pct",
    ROUND(r."avg_trip_duration_min", 4)                            AS "avg_trip_duration_min"
FROM ranked r
CROSS JOIN overall o
WHERE r."rk" <= 15
ORDER BY r."rk", r."station_id";