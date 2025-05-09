WITH active_stations AS (
    SELECT "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    WHERE UPPER("status") = 'ACTIVE'
),
station_trip_stats AS (
    SELECT
        t."start_station_id"              AS station_id,
        COUNT(*)                          AS start_trip_count,
        AVG(t."duration_minutes")         AS avg_trip_minutes
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
    JOIN active_stations s
      ON t."start_station_id" = s."station_id"
    GROUP BY t."start_station_id"
),
totals AS (
    SELECT SUM(start_trip_count) AS total_trips
    FROM station_trip_stats
),
ranked AS (
    SELECT
        sts.station_id,
        sts.start_trip_count,
        (sts.start_trip_count / total.total_trips) * 100  AS pct_of_total,
        sts.avg_trip_minutes,
        DENSE_RANK() OVER (ORDER BY sts.start_trip_count DESC) AS rk
    FROM station_trip_stats sts
    CROSS JOIN totals total
)
SELECT
    station_id                 AS "station_id",
    start_trip_count           AS "total_starting_trips",
    ROUND(pct_of_total, 4)     AS "percent_of_total_trips",
    ROUND(avg_trip_minutes, 4) AS "average_trip_duration_minutes"
FROM ranked
WHERE rk <= 15
ORDER BY rk, station_id;