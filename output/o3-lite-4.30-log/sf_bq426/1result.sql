WITH zip10019 AS (  -- polygon for NYC ZIP 10019
    SELECT "zip_code_geom"
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE  "zip_code" = '10019'
      AND  "state_code" = 'NY'
    LIMIT 1
),    
rides AS (          -- 2018 trips whose START and END lie in ZIP 10019
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1000000)) AS "ride_date",
        t."usertype"
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    CROSS  JOIN zip10019 z
    WHERE  t."starttime" BETWEEN 1514764800000000 AND 1546300799000000  -- 2018-01-01..2018-12-31
      AND  ST_WITHIN(
              TO_GEOGRAPHY('POINT(' || t."start_station_longitude" || ' ' || t."start_station_latitude" || ')'),
              TO_GEOGRAPHY(z."zip_code_geom")
           )
      AND  ST_WITHIN(
              TO_GEOGRAPHY('POINT(' || t."end_station_longitude" || ' ' || t."end_station_latitude" || ')'),
              TO_GEOGRAPHY(z."zip_code_geom")
           )
),    
weather AS (        -- daily Central Park weather (filter out missing‑value sentinels)
    SELECT
        TO_DATE(w."year" || '-' || w."mo" || '-' || w."da") AS "wx_date",
        w."temp",
        w."prcp",
        TO_NUMBER(w."wdsp") AS "wdsp"                       -- convert from text to number
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018 w
    WHERE  w."wban" = '94728'      -- New York Central Park station
      AND  w."temp" < 9999
      AND  w."prcp" < 99.99
      AND  TO_NUMBER(w."wdsp") < 999
)    
SELECT
    r."usertype"                                                AS user_type,
    ROUND(AVG(w."temp"),                       4)               AS average_temperature_f,
    ROUND(AVG(w."prcp"),                       4)               AS average_precipitation_in,
    ROUND(AVG(w."wdsp") * 1.15078,             4)               AS average_wind_speed_mph
FROM   rides   r
JOIN   weather w
  ON   r."ride_date" = w."wx_date"
GROUP  BY r."usertype"
ORDER  BY average_temperature_f DESC NULLS LAST
LIMIT  1;