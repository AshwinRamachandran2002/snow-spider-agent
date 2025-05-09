WITH zip10019 AS (   -- geometry for ZIP code 10019
    SELECT "zip_code_geom"
    FROM   NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE  "zip_code" = '10019'
),

trips_2018 AS (      -- all 2018 trips with start & end coordinates
    SELECT  t."usertype",
            TO_DATE( TO_TIMESTAMP_NTZ( t."starttime" / 1000000) ) AS trip_date,
            t."start_station_latitude"   AS s_lat,
            t."start_station_longitude"  AS s_lon,
            t."end_station_latitude"     AS e_lat,
            t."end_station_longitude"    AS e_lon
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    WHERE   YEAR( TO_TIMESTAMP_NTZ( t."starttime" / 1000000) ) = 2018
),

filtered_trips AS (  -- trips whose start AND end are inside ZIP 10019
    SELECT  tr."usertype",
            tr.trip_date
    FROM    trips_2018 tr
    CROSS JOIN zip10019 z
    WHERE   ST_CONTAINS( TO_GEOGRAPHY( z."zip_code_geom"),
                         TO_GEOGRAPHY( 'POINT('||tr.s_lon||' '||tr.s_lat||')') )
      AND   ST_CONTAINS( TO_GEOGRAPHY( z."zip_code_geom"),
                         TO_GEOGRAPHY( 'POINT('||tr.e_lon||' '||tr.e_lat||')') )
),

central_park AS (    -- identify Central Park weather-station code
    SELECT  "usaf" AS stn ,
            "wban" AS wban
    FROM    NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
    WHERE   UPPER("name") LIKE '%CENTRAL PARK%'
      AND   "country"      = 'US'
    QUALIFY ROW_NUMBER() OVER (ORDER BY "end" DESC NULLS LAST) = 1   -- keep 1 row
),

weather AS (         -- 2018 daily weather for Central Park
    SELECT
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) AS wdate,
        CAST("temp" AS FLOAT) AS temp,
        CAST("prcp" AS FLOAT) AS prcp,
        CAST("wdsp" AS FLOAT) AS wdsp
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018 g
    JOIN   central_park cp
           ON g."stn"  = cp.stn
          AND g."wban" = cp.wban
    WHERE  "temp" < 9999.9          -- exclude missing values
),

trip_weather AS (    -- attach weather to each selected trip
    SELECT  f."usertype",
            w.temp,
            w.prcp,
            w.wdsp
    FROM    filtered_trips f
    JOIN    weather w
           ON f.trip_date = w.wdate
),

stats AS (           -- average weather by user type
    SELECT  "usertype",
            AVG(temp)  AS avg_temp,
            AVG(prcp)  AS avg_prcp,
            AVG(wdsp)  AS avg_wdsp
    FROM    trip_weather
    GROUP BY "usertype"
),

best AS (            -- user type with highest average temperature
    SELECT *
    FROM   stats
    ORDER  BY avg_temp DESC NULLS LAST
    LIMIT  1
)

SELECT *
FROM   best;