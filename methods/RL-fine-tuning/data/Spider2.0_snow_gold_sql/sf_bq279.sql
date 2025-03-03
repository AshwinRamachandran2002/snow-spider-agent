SELECT
    YEAR,
    COUNT(DISTINCT CASE WHEN bs."status" = 'active' THEN stations_used."station_id" END) AS "Number_of_Stations_active",
    COUNT(DISTINCT CASE WHEN bs."status" = 'closed' THEN stations_used."station_id" END) AS "Number_of_Stations_closed"
FROM (
    SELECT
        DATE_PART(year, TO_TIMESTAMP(bt."start_time" / 1000000)) AS YEAR,
        bt."start_station_id" AS "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS bt
    WHERE DATE_PART(year, TO_TIMESTAMP(bt."start_time" / 1000000)) IN (2013, 2014)
    UNION
    SELECT
        DATE_PART(year, TO_TIMESTAMP(bt."start_time" / 1000000)) AS YEAR,
        TRY_TO_NUMBER(bt."end_station_id") AS "station_id"
    FROM AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_TRIPS bt
    WHERE DATE_PART(year, TO_TIMESTAMP(bt."start_time" / 1000000)) IN (2013, 2014)
) AS stations_used
LEFT JOIN AUSTIN.AUSTIN_BIKESHARE.BIKESHARE_STATIONS bs
    ON stations_used."station_id" = bs."station_id"
GROUP BY YEAR
ORDER BY YEAR;