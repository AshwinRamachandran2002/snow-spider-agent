WITH zip_10019 AS (  -- geometry for NYC ZIP code 10019
    SELECT "zip_code_geom"
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE  "zip_code" = '10019'
      AND  "state_code" = 'NY'
),

trips_2018 AS (      -- 2018 Citi Bike trips that start AND end inside ZIP 10019
    SELECT
        TO_DATE(TO_TIMESTAMP("starttime" / 1000000))           AS trip_date,
        "usertype"
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    JOIN zip_10019 z
      ON  ST_WITHIN(
              ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude"),
              TO_GEOGRAPHY(z."zip_code_geom")
          )
      AND ST_WITHIN(
              ST_MAKEPOINT(t."end_station_longitude",   t."end_station_latitude"),
              TO_GEOGRAPHY(z."zip_code_geom")
          )
    WHERE TO_DATE(TO_TIMESTAMP("starttime" / 1000000))
          BETWEEN '2018-01-01' AND '2018-12-31'
),

weather_cp AS (      -- 2018 daily weather from Central Park station (WBAN 94728)
    SELECT
        TO_DATE(CONCAT("year",'-',LPAD("mo",2,'0'),'-',LPAD("da",2,'0'))) AS obs_date,
        CAST("temp" AS FLOAT)  AS temp,
        CAST("prcp" AS FLOAT)  AS prcp,
        CAST("wdsp" AS FLOAT)  AS wdsp                 -- knots
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018
    WHERE "wban" = '94728'
)

SELECT
    t."usertype"                                               AS user_type,
    ROUND(AVG(w.temp),   4)                                    AS average_temperature_f,
    ROUND(AVG(w.prcp),   4)                                    AS average_precipitation_in,
    ROUND(AVG(w.wdsp) * 1.15078, 4)                            AS average_wind_speed_mph  -- knots → mph
FROM trips_2018 t
JOIN weather_cp w
  ON t.trip_date = w.obs_date
GROUP BY t."usertype"
ORDER BY average_temperature_f DESC
LIMIT 1;