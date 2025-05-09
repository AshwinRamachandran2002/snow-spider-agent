/*-------------------------------------------------------------
  Highest-average Central-Park weather by Citi Bike user type
  for rides that BOTH start and finish inside ZIP-code 10019
  during calendar-year 2018
--------------------------------------------------------------*/
WITH

/* 1 ─ Identify the Central-Park weather-station codes          */
central_park_station AS (
    SELECT DISTINCT
           TRIM("usaf") AS usaf ,
           TRIM("wban") AS wban
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE  UPPER("name")  LIKE '%CENTRAL PARK%'
      AND  "state"        = 'NY'
      AND  "country"      = 'US'
),

/* 2 ─ Daily Central-Park weather for 2018                      */
weather_2018 AS (
    SELECT
        TO_DATE(TO_CHAR("year")||'-'
                ||LPAD("mo",2,'0')||'-'
                ||LPAD("da",2,'0'))                 AS weather_day ,
        "temp"                                      AS mean_temp_f ,
        "prcp"                                      AS total_prcp_in ,
        TRY_TO_NUMBER("wdsp")                       AS mean_wdsp_kt
    FROM  NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018    w
          JOIN central_park_station c
            ON w."stn"  = c.usaf
           AND w."wban" = c.wban
),

/* 3 ─ Geometry for Manhattan ZIP-code 10019                    */
zip_10019 AS (
    SELECT ST_GEOGFROMWKB("zip_code_geom") AS geom
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE  "zip_code" = '10019'
),

/* 4 ─ 2018 trips whose *start* AND *end* points are in ZIP 10019*/
trips_in_zip AS (
    SELECT
        t."usertype",
        TO_DATE( TO_TIMESTAMP_LTZ(t."starttime"/1e6) )  AS trip_day
    FROM  NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
          CROSS JOIN zip_10019 z
    WHERE YEAR( TO_TIMESTAMP_LTZ(t."starttime"/1e6) ) = 2018
      AND ST_CONTAINS( z.geom ,
                       ST_MAKEPOINT(t."start_station_longitude",
                                    t."start_station_latitude") )
      AND ST_CONTAINS( z.geom ,
                       ST_MAKEPOINT(t."end_station_longitude",
                                    t."end_station_latitude") )
)

/* 5 ─ Combine trips with daily weather and take averages        */
SELECT
    tr."usertype"                           AS user_type ,
    AVG(w.mean_temp_f)                      AS avg_temperature_f ,
    AVG(w.total_prcp_in)                    AS avg_precipitation_in ,
    AVG(w.mean_wdsp_kt)                     AS avg_wind_speed_kt
FROM   trips_in_zip tr
       JOIN weather_2018 w
         ON w.weather_day = tr.trip_day
GROUP BY tr."usertype"
ORDER BY avg_temperature_f DESC NULLS LAST;