WITH trip_station AS (
    SELECT
        YEAR(TO_TIMESTAMP("start_time" / 1000000))      AS "year",
        t."start_station_id"                            AS "station_id",
        LOWER(TRIM(s."status"))                         AS "station_status"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS  t
    LEFT JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS s
           ON t."start_station_id" = s."station_id"
    WHERE YEAR(TO_TIMESTAMP("start_time" / 1000000)) IN (2013, 2014)
)
SELECT
    "year",
    CASE 
        WHEN "station_status" = 'active' THEN 'Active'
        WHEN "station_status" = 'closed' THEN 'Closed'
        ELSE 'Other'
    END                                                AS "station_status",
    COUNT(DISTINCT "station_id")                       AS "distinct_station_count"
FROM trip_station
GROUP BY "year", "station_status"
ORDER BY "year", "station_status";