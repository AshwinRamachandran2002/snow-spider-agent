SELECT
    t."start_station_id" AS station_id,
    COUNT(*) AS total_number_of_trips,
    ROUND((COUNT(*)::float / total.total_trips_from_active_stations * 100), 4) AS percentage_of_total_trips,
    ROUND(AVG(t."duration_minutes"), 4) AS average_duration_minutes
FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
    ON t."start_station_id" = s."station_id"
CROSS JOIN (
    SELECT COUNT(*) AS total_trips_from_active_stations
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t2
    JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s2
        ON t2."start_station_id" = s2."station_id"
    WHERE s2."status" = 'active'
) total
WHERE s."status" = 'active'
GROUP BY t."start_station_id", total.total_trips_from_active_stations
ORDER BY total_number_of_trips DESC NULLS LAST
LIMIT 15;