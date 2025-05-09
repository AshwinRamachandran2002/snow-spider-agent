WITH stations_with_dates AS (
    SELECT usaf, wban, PARSE_DATE('%Y%m%d', begin) AS begin_date, PARSE_DATE('%Y%m%d', `end`) AS end_date
    FROM `bigquery-public-data.noaa_gsod.stations`
),
stations_filtered AS (
    SELECT usaf, wban
    FROM stations_with_dates
    WHERE begin_date <= DATE '2000-01-01' AND end_date >= DATE '2019-06-30'
),
valid_temps AS (
    SELECT stn, wban, COUNT(*) AS valid_temp_days
    FROM `bigquery-public-data.noaa_gsod.gsod2019`
    WHERE temp != 9999.9
    GROUP BY stn, wban
),
valid_temps_filtered AS (
    SELECT vt.stn, vt.wban, vt.valid_temp_days
    FROM valid_temps vt
    JOIN stations_filtered sf ON vt.stn = sf.usaf AND vt.wban = sf.wban
),
max_days AS (
    SELECT MAX(valid_temp_days) AS max_valid_days
    FROM valid_temps_filtered
)
SELECT COUNT(DISTINCT stn) AS Number_of_Stations
FROM valid_temps_filtered vt
CROSS JOIN max_days
WHERE vt.valid_temp_days >= 0.9 * max_days.max_valid_days;