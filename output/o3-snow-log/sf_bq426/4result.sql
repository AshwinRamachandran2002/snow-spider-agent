/*------------------------------------------------------------------
  Find which Citi Bike user-type recorded the highest average daily
  temperature on trips that both STARTED and ENDED inside Manhattan
  ZIP-code 10019 in calendar-year 2018, together with their average
  precipitation and wind-speed (Central Park GSOD station).
------------------------------------------------------------------*/
WITH
/* 1)  Central-Park GSOD station (USAF / WBAN)               */
central_park AS (
    SELECT "usaf" AS stn , "wban" AS wban
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE  UPPER("name") LIKE '%CENTRAL PARK%'
      AND  "state" = 'NY'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC NULLS LAST) = 1
),
/* 2)  GEOGRAPHY for ZIP 10019                               */
zip_10019 AS (
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE  "zip_code" = '10019'
      AND  "state_code" = 'NY'
),
/* 3)  2018 Citi-Bike trips whose start- and end-points are
        both inside that ZIP (use lat/lon in trip table).    */
trips_2018_10019 AS (
    SELECT
        t."usertype",
        TO_DATE(TO_TIMESTAMP_NTZ(t."starttime"/1e6)) AS trip_date
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
           , zip_10019 z
    WHERE  YEAR(TO_TIMESTAMP_NTZ(t."starttime"/1e6)) = 2018
      AND  t."start_station_latitude"  IS NOT NULL
      AND  t."start_station_longitude" IS NOT NULL
      AND  t."end_station_latitude"    IS NOT NULL
      AND  t."end_station_longitude"   IS NOT NULL
      AND  ST_WITHIN(
             ST_POINT(t."start_station_longitude",
                       t."start_station_latitude"),
             z.geom )
      AND  ST_WITHIN(
             ST_POINT(t."end_station_longitude",
                       t."end_station_latitude"),
             z.geom )
),
/* 4)  Daily Central-Park weather for 2018                    */
weather_2018_cp AS (
    SELECT
        TO_DATE(CONCAT_WS('-', "year","mo","da"))                     AS weather_date,
        "temp"                                                       AS temp_f,
        /* treat GSOD missing codes (99.99 / 999.9) as NULL          */
        NULLIF("prcp", 99.99)                                        AS prcp_in,
        NULLIF(TRY_TO_DOUBLE("wdsp"), 999.9)                         AS wind_kts
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018 g
           JOIN central_park cp
             ON g."stn"  = cp.stn
            AND g."wban" = cp.wban
    WHERE  "temp" <> 9999.9
)
/* 5)  Bring trips together with same-day weather and choose
        the user-type with the highest average temperature.  */
SELECT
    t."usertype"                          AS user_type,
    ROUND(AVG(w.temp_f), 2)               AS avg_temperature_f,
    ROUND(AVG(w.prcp_in), 2)              AS avg_precipitation_in,
    ROUND(AVG(w.wind_kts), 2)             AS avg_wind_speed_kts
FROM   trips_2018_10019 t
       JOIN weather_2018_cp w
         ON w.weather_date = t.trip_date
GROUP  BY t."usertype"
ORDER  BY avg_temperature_f DESC NULLS LAST
LIMIT  1;