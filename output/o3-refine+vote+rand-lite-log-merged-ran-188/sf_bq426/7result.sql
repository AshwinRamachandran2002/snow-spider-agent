/*  Highest-average-temperature Citi Bike user-type for trips that both
    start and end inside Manhattan ZIP 10019 during calendar-year 2018,
    along with that user-type’s average daily precipitation and wind speed.
*/
WITH zip10019 AS (   -- polygon for ZIP 10019
    SELECT "zip_code_geom"
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE  "zip_code" = '10019'
), ---------------------------------------------------------------
stations_in_zip AS (                           -- station names in 10019
    SELECT DISTINCT s."name"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_STATIONS" s
    JOIN   zip10019 z
      ON   ST_WITHIN(
             TO_GEOGRAPHY(
                 CONCAT('POINT(', s."longitude", ' ', s."latitude", ')')
             ),
             TO_GEOGRAPHY(z."zip_code_geom")
           )
), ---------------------------------------------------------------
trips_2018 AS (          -- 2018 trips whose start & end stations are in 10019
    SELECT
        t."usertype",
        TO_DATE(TO_TIMESTAMP_LTZ(t."starttime" / 1000000)) AS "trip_date"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE  TO_TIMESTAMP_LTZ(t."starttime" / 1000000) >= '2018-01-01'
      AND  TO_TIMESTAMP_LTZ(t."starttime" / 1000000) <  '2019-01-01'
      AND  t."start_station_name" IN (SELECT "name" FROM stations_in_zip)
      AND  t."end_station_name"   IN (SELECT "name" FROM stations_in_zip)
), ---------------------------------------------------------------
central_park_weather AS (          -- daily Central Park weather for 2018
    SELECT
        TO_DATE(CONCAT("year",'-', LPAD("mo",2,'0'),'-', LPAD("da",2,'0'))) AS "wx_date",
        "temp"                                         AS "temp_f",
        "prcp"                                         AS "prcp_in",
        CAST("wdsp" AS FLOAT)                          AS "wind_knots"
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018"
    WHERE  "wban" = '94728'        -- New York Central Park station
      AND  "temp" <>  9999.9
      AND  "prcp" <>   99.99
      AND  "wdsp" <>   999.9
) ---------------------------------------------------------------
SELECT
    res."usertype",
    ROUND(res."avg_temp_f", 4)  AS "avg_temperature_f",
    ROUND(res."avg_prcp_in",4)  AS "avg_precipitation_in",
    ROUND(res."avg_wind_knots",4) AS "avg_wind_speed_knots"
FROM (
    SELECT
        t."usertype",
        AVG(w."temp_f")   AS "avg_temp_f",
        AVG(w."prcp_in")  AS "avg_prcp_in",
        AVG(w."wind_knots") AS "avg_wind_knots",
        ROW_NUMBER() OVER (ORDER BY AVG(w."temp_f") DESC NULLS LAST) AS rn
    FROM   trips_2018 t
    JOIN   central_park_weather w
           ON t."trip_date" = w."wx_date"
    GROUP  BY t."usertype"
) res
WHERE res.rn = 1;