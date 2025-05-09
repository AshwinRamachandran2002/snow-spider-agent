WITH
    station_trip_stats AS (
        SELECT
            s."station_id",
            COUNT(*) AS "total_trips",
            AVG(t."duration_minutes") AS "average_trip_duration_minutes"
        FROM
            AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
            JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
                ON t."start_station_id" = s."station_id"
        WHERE
            s."status" = 'active'
        GROUP BY
            s."station_id"
    ),
    total_trips_active AS (
        SELECT
            COUNT(*) AS total_trips_active
        FROM
            AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
            JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
                ON t."start_station_id" = s."station_id"
        WHERE
            s."status" = 'active'
    ),
    ranked_stations AS (
        SELECT
            sts.*,
            RANK() OVER (ORDER BY sts."total_trips" DESC) AS station_rank
        FROM
            station_trip_stats sts
    ),
    cutoff_total_trips AS (
        SELECT
            MIN("total_trips") AS cutoff_total_trips
        FROM
            ranked_stations
        WHERE
            station_rank <= 15
    )
SELECT
    rs."station_id",
    rs."total_trips",
    ROUND((rs."total_trips" * 100.0) / tta.total_trips_active, 6) AS "percentage_of_total_starting_trips",
    ROUND(rs."average_trip_duration_minutes", 6) AS "average_trip_duration_minutes"
FROM
    ranked_stations rs
    CROSS JOIN total_trips_active tta
WHERE
    rs."total_trips" >= (SELECT cutoff_total_trips FROM cutoff_total_trips)
ORDER BY
    rs."total_trips" DESC NULLS LAST;