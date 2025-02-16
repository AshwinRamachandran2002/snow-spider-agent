-- Task: Can you provide the number of distinct bike share stations used for each year 2013 and 2014?
SELECT
    YEAR,
    COUNT(DISTINCT stations_used."station_id") AS "Number_of_Stations"
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
GROUP BY YEAR
ORDER BY YEAR;