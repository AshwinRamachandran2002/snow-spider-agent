-- Task: Provide the daily weather data for Rochester from January 1 to March 31, 2019, including temperature (in Celsius), precipitation (in centimeters), and wind speed (in meters per second). Round all values to one decimal place. The data should be ordered by date.

SELECT
    DATE(CAST(year AS INT64), CAST(mo AS INT64), CAST(da AS INT64)) AS observation_date,
    ROUND((temp - 32.0) / 1.8, 1) AS temp_mean_c, -- Celsius
    ROUND(prcp * 2.54, 1) AS prcp_cm, -- centimeters
    ROUND(CAST(wdsp AS FLOAT64) * 1.852 / 3.6, 1) AS wdsp_ms -- meters per second
FROM `bigquery-public-data.noaa_gsod.gsod*`
WHERE _TABLE_SUFFIX = "2019"
    AND CAST(mo AS INT64) <= 3
    AND stn IN (SELECT usaf FROM `bigquery-public-data.noaa_gsod.stations` WHERE name = "ROCHESTER")
ORDER BY observation_date;