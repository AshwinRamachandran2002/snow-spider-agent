WITH zip_geom AS (   -- polygon for ZIP 10019, NY
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE "zip_code" = '10019'
      AND "state_code" = 'NY'
),
-- 2018 trips whose start AND end locations fall inside ZIP 10019
trips_10019_2018 AS (
    SELECT
        t."usertype",
        DATE( TO_TIMESTAMP_LTZ(t."starttime" / 1e6) ) AS trip_date
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS"  t
    CROSS JOIN zip_geom z
    WHERE YEAR( TO_TIMESTAMP_LTZ(t."starttime" / 1e6) ) = 2018
      AND ST_WITHIN(
              TO_GEOGRAPHY('POINT('||t."start_station_longitude"||' '||t."start_station_latitude"||')'),
              z.geom
          )
      AND ST_WITHIN(
              TO_GEOGRAPHY('POINT('||t."end_station_longitude"||' '||t."end_station_latitude"||')'),
              z.geom
          )
),
-- daily Central Park, NY weather for 2018
weather_2018 AS (
    SELECT
        TO_DATE(CONCAT(g."year",'-',LPAD(g."mo",2,'0'),'-',LPAD(g."da",2,'0')))     AS weather_date,
        CAST(g."temp" AS FLOAT)                                                     AS temp_f,
        CAST(g."prcp" AS FLOAT)                                                     AS prcp_in,
        CAST(g."wdsp" AS FLOAT)                                                     AS wdsp_kt
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018"           g
    JOIN NEW_YORK_CITIBIKE_1.NOAA_GSOD."STATIONS"           s
          ON g."stn" = s."usaf"  AND g."wban" = s."wban"
    WHERE UPPER(s."name") LIKE '%CENTRAL PARK%'
      AND s."state" = 'NY'
)
-- combine trips with weather and pick the user type with the highest
-- average temperature (return its averages for all three measures)
SELECT
    t."usertype",
    AVG(w.temp_f)  AS avg_temperature_f,
    AVG(w.prcp_in) AS avg_precipitation_in,
    AVG(w.wdsp_kt) AS avg_wind_speed_kt
FROM trips_10019_2018  t
JOIN weather_2018      w
     ON t.trip_date = w.weather_date
GROUP BY t."usertype"
QUALIFY ROW_NUMBER() OVER (ORDER BY avg_temperature_f DESC) = 1;