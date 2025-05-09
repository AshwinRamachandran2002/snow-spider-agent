SELECT
    CAST(t."start_station_id" AS INT) AS "station_id",
    COUNT(*) AS "total_number_of_trips",
    ROUND(COUNT(*) * 100.0 / (
        SELECT COUNT(*)
        FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t2
        JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s2
          ON CAST(t2."start_station_id" AS INT) = s2."station_id"
        WHERE s2."status" = 'active'
    ), 4) AS "percentage_of_total_trips",
    ROUND(AVG(t."duration_minutes"), 4) AS "average_duration_minutes"
FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS t
JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
  ON CAST(t."start_station_id" AS INT) = s."station_id"
WHERE s."status" = 'active'
GROUP BY CAST(t."start_station_id" AS INT)
ORDER BY "total_number_of_trips" DESC NULLS LAST
LIMIT 15;