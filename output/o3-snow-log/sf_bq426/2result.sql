WITH zip10019 AS (   -----------------------------------------------------------
    -- Geometry for Manhattan ZIP code 10019
    -----------------------------------------------------------
    SELECT
        ST_GEOGFROMWKB("zip_code_geom") AS geom
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE  "zip_code" = '10019'
      AND  "state_code" = 'NY'
),

trips_10019_2018 AS (   --------------------------------------------------------
    -- 2018 Citi Bike trips whose   start *and* finish are inside ZIP 10019
    --------------------------------------------------------
    SELECT
        t."usertype",
        CAST(TO_TIMESTAMP(t."starttime" / 1e6) AS DATE) AS trip_date
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
           CROSS JOIN zip10019 z
    WHERE  EXTRACT(YEAR FROM TO_TIMESTAMP(t."starttime" / 1e6)) = 2018
      AND  ST_INTERSECTS( z.geom ,
                          ST_POINT(t."start_station_longitude",
                                   t."start_station_latitude") )
      AND  ST_INTERSECTS( z.geom ,
                          ST_POINT(t."end_station_longitude"  ,
                                   t."end_station_latitude") )
),

central_park_weather_2018 AS (   ----------------------------------------------
    -- 2018 GSOD daily weather for NYC Central Park (WBAN 94728)
    ----------------------------------------------
    SELECT
        TO_DATE(CONCAT("year",'-', "mo",'-', "da"))      AS trip_date,
        "temp"                                           AS temp_f,
        "prcp"                                           AS prcp_in,
        TRY_CAST("wdsp" AS FLOAT)                        AS wdsp_knots
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018"
    WHERE  "wban" = '94728'           -- Central Park WBAN
      AND  "temp" <> 9999.9
)

SELECT
    t."usertype"                         AS user_type,
    ROUND(AVG(w.temp_f)     , 2)         AS avg_temperature_f,
    ROUND(AVG(w.prcp_in)    , 4)         AS avg_precipitation_in,
    ROUND(AVG(w.wdsp_knots) , 2)         AS avg_wind_speed_knots
FROM   trips_10019_2018 t
JOIN   central_park_weather_2018 w
       ON t.trip_date = w.trip_date
GROUP  BY t."usertype"
ORDER  BY avg_temperature_f DESC NULLS LAST
LIMIT  1;