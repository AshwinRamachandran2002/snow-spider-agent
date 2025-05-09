WITH trip_station_year AS (
    /* collect every station that recorded at least one trip in 2013 or 2014 */
    SELECT
        DATE_PART('year', TO_TIMESTAMP("start_time" / 1000000))        AS "year",
        "start_station_id"                                            AS "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS

    UNION ALL

    SELECT
        DATE_PART('year', TO_TIMESTAMP("start_time" / 1000000))        AS "year",
        TRY_TO_NUMBER("end_station_id")                               AS "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
),
station_status AS (
    SELECT
        "station_id",
        LOWER("status") AS "status"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
)
SELECT
    ts."year",
    COUNT(DISTINCT CASE WHEN ss."status" <> 'closed' THEN ts."station_id" END) AS "active_stations",
    COUNT(DISTINCT CASE WHEN ss."status"  = 'closed' THEN ts."station_id" END) AS "closed_stations"
FROM trip_station_year ts
LEFT JOIN station_status ss
       ON ts."station_id" = ss."station_id"
WHERE ts."year" IN (2013, 2014)
GROUP BY ts."year"
ORDER BY ts."year";