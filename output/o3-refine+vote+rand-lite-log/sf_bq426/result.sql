WITH zip_10019 AS (  -- GEOGRAPHY for ZIP 10019
    SELECT TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE  "zip_code" = '10019'
),

trips_2018 AS (      -- 2018 trips whose start and end are within ZIP 10019
    SELECT  t."usertype",
            TO_DATE(TO_TIMESTAMP_LTZ(t."starttime" / 1000000)) AS trip_date
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t,
            zip_10019 z
    WHERE   EXTRACT(YEAR FROM TO_TIMESTAMP_LTZ(t."starttime" / 1000000)) = 2018
      AND   ST_WITHIN(
                TO_GEOGRAPHY(ST_POINT(t."start_station_longitude",
                                      t."start_station_latitude")),
                z.geom)
      AND   ST_WITHIN(
                TO_GEOGRAPHY(ST_POINT(t."end_station_longitude",
                                      t."end_station_latitude")),
                z.geom)
),

central_park_station AS (   -- Central Park GSOD station (NY)
    SELECT  "usaf", "wban"
    FROM    NEW_YORK_CITIBIKE_1.NOAA_GSOD."STATIONS"
    WHERE   UPPER("name") LIKE '%CENTRAL PARK%'
      AND   "state" = 'NY'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC) = 1   -- pick most‑recent record
),

weather_2018 AS (     -- 2018 Central Park daily weather
    SELECT  DATE_FROM_PARTS(2018, TO_NUMBER("mo"), TO_NUMBER("da")) AS wx_date,
            NULLIF("temp", 9999.9)                 AS temp_f,
            NULLIF("prcp",  99.99)                 AS prcp_in,
            NULLIF(TO_NUMBER("wdsp"), 999.9)       AS wdsp_knots
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2018"  w
           JOIN central_park_station s
             ON w."stn"  = s."usaf"
            AND w."wban" = s."wban"
),

trip_weather AS (     -- combine trips with same‑day weather
    SELECT  t."usertype",
            w.temp_f,
            w.prcp_in,
            w.wdsp_knots
    FROM    trips_2018 t
           JOIN weather_2018 w
             ON t.trip_date = w.wx_date
),

agg AS (               -- average weather by user type
    SELECT  "usertype",
            AVG(temp_f)        AS avg_temp_f,
            AVG(prcp_in)       AS avg_prcp_in,
            AVG(wdsp_knots)    AS avg_wdsp_knots
    FROM    trip_weather
    GROUP BY "usertype"
)

SELECT  "usertype"      AS user_type,
        avg_temp_f,
        avg_prcp_in,
        avg_wdsp_knots
FROM    agg
ORDER BY avg_temp_f DESC NULLS LAST
LIMIT 1;