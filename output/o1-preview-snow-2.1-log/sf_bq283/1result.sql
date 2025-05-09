SELECT
    t."start_station_id" AS "station_id",
    COUNT(*) AS "total_number_of_trips",
    ROUND((COUNT(*) * 100.0) / (
        SELECT COUNT(*)
        FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS AS t2
        JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS AS s2
          ON t2."start_station_id" = s2."station_id"
        WHERE s2."status" = 'active'
    ), 4) AS "percentage_of_total_trips",
    ROUND(AVG(t."duration_minutes"), 4) AS "average_duration_minutes"
FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS AS t
JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS AS s
  ON t."start_station_id" = s."station_id"
WHERE s."status" = 'active'
GROUP BY t."start_station_id"
ORDER BY "total_number_of_trips" DESC NULLS LAST, t."start_station_id" ASC
LIMIT 15;