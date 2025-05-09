SELECT
    a."Year",
    COUNT(DISTINCT a."station_id") AS "Number_of_Stations_active",
    ts."Total_stations" - COUNT(DISTINCT a."station_id") AS "Number_of_Stations_closed"
FROM
    (
        SELECT
            EXTRACT(year FROM TO_TIMESTAMP_NTZ("start_time" / 1000000)) AS "Year",
            "start_station_id" AS "station_id"
        FROM
            AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS
        WHERE
            EXTRACT(year FROM TO_TIMESTAMP_NTZ("start_time" / 1000000)) IN (2013, 2014)
    ) a
    CROSS JOIN (
        SELECT COUNT(DISTINCT "station_id") AS "Total_stations"
        FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS
    ) ts
GROUP BY
    a."Year", ts."Total_stations"
ORDER BY
    a."Year";