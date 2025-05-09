WITH zip_geom AS (                                 /* ZIP‑code 10019 geometry */
    SELECT ST_GEOGFROMWKB("zip_code_geom") AS geom
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE  "zip_code" = '10019'
),
trips_2018 AS (                                    /* 2018 trips wholly inside ZIP‑10019 */
    SELECT
        t."usertype",
        TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1000000)) AS trip_date
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    CROSS  JOIN zip_geom z
    WHERE  YEAR(TO_DATE(TO_TIMESTAMP_NTZ(t."starttime" / 1000000))) = 2018
      AND  ST_WITHIN(ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude"), z.geom)
      AND  ST_WITHIN(ST_MAKEPOINT(t."end_station_longitude"  , t."end_station_latitude")  , z.geom)
),
central_park_weather AS (                          /* 2018 Central Park weather */
    SELECT
        TO_DATE(g."year"||'-'||LPAD(g."mo",2,'0')||'-'||LPAD(g."da",2,'0')) AS wx_date,
        g."temp",
        g."prcp",
        TRY_TO_DOUBLE(g."wdsp") AS wdsp_knots
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018 g
    JOIN   NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS s
           ON s."usaf" = g."stn"  AND s."wban" = g."wban"
    WHERE  s."name" ILIKE '%CENTRAL PARK%'
),
joined_data AS (                                   /* Match trips to same‑day weather */
    SELECT
        t."usertype",
        w."temp",
        w."prcp",
        w.wdsp_knots
    FROM trips_2018 t
    JOIN central_park_weather w
      ON t.trip_date = w.wx_date
),
agg AS (                                           /* Averages by user type */
    SELECT
        "usertype",
        ROUND(AVG("temp")                       ,4) AS average_temperature_f,
        ROUND(AVG("prcp")                       ,4) AS average_precipitation_in,
        ROUND(AVG(wdsp_knots * 1.150779)        ,4) AS average_wind_speed_mph  /* knots → mph */
    FROM joined_data
    GROUP BY "usertype"
)
SELECT                                              /* User type with highest avg temp */
    "usertype"              AS user_type,
    average_temperature_f,
    average_precipitation_in,
    average_wind_speed_mph
FROM   agg
ORDER  BY average_temperature_f DESC NULLS LAST
LIMIT  1;