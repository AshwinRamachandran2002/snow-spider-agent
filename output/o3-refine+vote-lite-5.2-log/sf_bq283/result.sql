WITH active_stations AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE LOWER("status") = 'active'
),
station_trip_stats AS (
    SELECT
        bt."start_station_id"    AS "station_id",
        COUNT(*)                 AS "start_trip_count",
        AVG(bt."duration_minutes") AS "avg_duration_minutes"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS bt
    JOIN active_stations s
          ON bt."start_station_id" = s."station_id"
    GROUP BY bt."start_station_id"
),
overall_totals AS (
    SELECT SUM("start_trip_count") AS "total_start_trips"
    FROM station_trip_stats
),
ranked_stations AS (
    SELECT
        sts."station_id",
        sts."start_trip_count",
        (sts."start_trip_count" * 100.0 / ot."total_start_trips") AS "pct_of_overall_start_trips",
        sts."avg_duration_minutes",
        DENSE_RANK() OVER (ORDER BY sts."start_trip_count" DESC) AS "rank"
    FROM station_trip_stats sts
    CROSS JOIN overall_totals ot
)
SELECT
    "station_id",
    "start_trip_count",
    ROUND("pct_of_overall_start_trips", 4) AS "pct_of_overall_start_trips",
    ROUND("avg_duration_minutes", 4)       AS "avg_duration_minutes"
FROM ranked_stations
WHERE "rank" <= 15
ORDER BY "rank", "station_id";