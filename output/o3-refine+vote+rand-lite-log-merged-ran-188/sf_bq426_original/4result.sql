WITH zip_poly AS (   -- polygon for Manhattan ZIP 10019
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "zip_code" = '10019'
),
trips_2018 AS (      -- 2018 trips whose start & end points fall inside 10019
    SELECT
        t."usertype",
        DATE_TRUNC('day', TO_TIMESTAMP_LTZ(t."starttime" / 1e6)) AS trip_date
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t,
         zip_poly z
    WHERE YEAR(TO_TIMESTAMP_LTZ(t."starttime" / 1e6)) = 2018
      AND ST_WITHIN(
              TO_GEOGRAPHY('POINT(' || t."start_station_longitude" || ' ' || t."start_station_latitude" || ')'),
              z.geom
          )
      AND ST_WITHIN(
              TO_GEOGRAPHY('POINT(' || t."end_station_longitude" || ' ' || t."end_station_latitude" || ')'),
              z.geom
          )
),
central_park_station AS (   -- Central Park NOAA GSOD station
    SELECT "usaf", "wban"
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE UPPER("name") LIKE '%CENTRAL PARK%'
      AND "state" = 'NY'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC NULLS LAST) = 1
),
weather_2018 AS (    -- daily weather for 2018 at Central Park
    SELECT
        TO_DATE(CONCAT("year", '-', "mo", '-', "da"))                 AS weather_date,
        "temp"                                        AS TEMP,        -- mean °F
        TRY_TO_NUMBER("wdsp")                         AS WDSP,        -- mean wind‑speed (knots)
        "prcp"                                        AS PRCP         -- precipitation (inches)
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018 w
    JOIN central_park_station s
      ON w."stn" = s."usaf" AND w."wban" = s."wban"
)
SELECT
    t."usertype",
    ROUND(AVG(w.TEMP), 4)  AS avg_temperature_f,
    ROUND(AVG(w.PRCP), 4)  AS avg_precip_in,
    ROUND(AVG(w.WDSP), 4)  AS avg_wind_speed_knots
FROM trips_2018 t
JOIN weather_2018 w
  ON t.trip_date = w.weather_date
GROUP BY t."usertype"
ORDER BY avg_temperature_f DESC NULLS LAST, t."usertype"
LIMIT 1;