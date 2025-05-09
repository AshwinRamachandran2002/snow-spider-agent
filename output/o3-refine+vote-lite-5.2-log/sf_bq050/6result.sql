/* ----------------------------------------------------------------------
   Bike–trip 2014 neighbourhood flow   +   Central‑Park weather (GSOD)
   -------------------------------------------------------------------- */
WITH

/* 1. NYC ZIP polygons ------------------------------------------------- */
nyc_zip AS (
    SELECT
        "zip_code"                                   AS zip,
        TO_GEOGRAPHY("zip_code_geom")                AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"
    WHERE "state_code" = 'NY'
),

/* 2. 2014 Citi Bike trips with points -------------------------------- */
trip_pts AS (
    SELECT
        t.*,
        DATE_TRUNC('day', TO_TIMESTAMP_LTZ(t."starttime"/1000000))           AS trip_date,
        EXTRACT(month FROM TO_TIMESTAMP_LTZ(t."starttime"/1000000))::INT     AS trip_month,
        (t."tripduration"/60.0)                                              AS dur_min,
        ST_MAKEPOINT(t."start_station_longitude", t."start_station_latitude") AS g_start,
        ST_MAKEPOINT(t."end_station_longitude"  , t."end_station_latitude")   AS g_end
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS"  t
    WHERE YEAR( TO_TIMESTAMP_LTZ(t."starttime"/1000000) ) = 2014
      AND t."start_station_latitude" IS NOT NULL
      AND t."end_station_latitude"   IS NOT NULL
),

/* 3. attach start/end ZIPs ------------------------------------------- */
trip_zip AS (
    SELECT
        p.*,
        zs.zip AS start_zip,
        ze.zip AS end_zip
    FROM trip_pts p
    LEFT JOIN nyc_zip zs ON ST_WITHIN(p.g_start , zs.geom)
    LEFT JOIN nyc_zip ze ON ST_WITHIN(p.g_end   , ze.geom)
),

/* 4. add borough & neighbourhood names ------------------------------- */
trip_nbhd AS (
    SELECT
        tz.*,
        cs."borough"      AS start_borough,
        cs."neighborhood" AS start_neigh,
        ce."borough"      AS end_borough,
        ce."neighborhood" AS end_neigh
    FROM trip_zip tz
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" cs
           ON tz.start_zip = cs."zip"
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" ce
           ON tz.end_zip   = ce."zip"
    WHERE cs."neighborhood" IS NOT NULL
      AND ce."neighborhood" IS NOT NULL
),

/* 5. Central‑Park daily weather for 2014 (station 725033‑94728) ------ */
wx AS (
    SELECT
        DATE_FROM_PARTS("year"::INT, "mo"::INT, "da"::INT)          AS wx_date,
        "temp"                                                     AS temp_f,
        CAST(NULLIF("wdsp",'999.9') AS FLOAT) * 0.514444            AS wind_mps,
        CASE WHEN "prcp" = 99.99 THEN NULL ELSE "prcp"*2.54 END     AS prcp_cm
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2014"
    WHERE "stn" = '725033'
      AND "wban" = '94728'
),

/* 6. trips joined with weather -------------------------------------- */
trip_wx AS (
    SELECT
        n.start_borough ,
        n.start_neigh   ,
        n.end_borough   ,
        n.end_neigh     ,
        n.trip_month    ,
        n.dur_min       ,
        w.temp_f        ,
        w.wind_mps      ,
        w.prcp_cm
    FROM trip_nbhd n
    LEFT JOIN wx w
           ON n.trip_date = w.wx_date
),

/* 7a. overall aggregates per pair ----------------------------------- */
pair_stats AS (
    SELECT
        start_borough,
        start_neigh,
        end_borough,
        end_neigh,
        COUNT(*)                              AS trips,
        ROUND(AVG(dur_min)  ,1)               AS avg_trip_min,
        ROUND(AVG(temp_f)   ,1)               AS avg_temp_f,
        ROUND(AVG(wind_mps) ,1)               AS avg_wind_mps,
        ROUND(AVG(prcp_cm)  ,1)               AS avg_prcp_cm
    FROM trip_wx
    GROUP BY 1,2,3,4
),

/* 7b. month with most trips ----------------------------------------- */
top_month AS (
    SELECT
        start_borough,
        start_neigh,
        end_borough,
        end_neigh,
        FIRST_VALUE(trip_month)
            OVER (PARTITION BY start_borough,start_neigh,end_borough,end_neigh
                  ORDER BY COUNT(*) DESC, trip_month)  AS busiest_month
    FROM trip_wx
    GROUP BY 1,2,3,4,trip_month
)

/* 8. final result ---------------------------------------------------- */
SELECT
    ps.start_borough        AS "START_BOROUGH",
    ps.start_neigh          AS "START_NEIGHBORHOOD",
    ps.end_borough          AS "END_BOROUGH",
    ps.end_neigh            AS "END_NEIGHBORHOOD",
    ps.trips                AS "TOTAL_TRIPS",
    ps.avg_trip_min         AS "AVG_TRIP_DURATION_MIN",
    ps.avg_temp_f           AS "AVG_TEMP_F",
    ps.avg_wind_mps         AS "AVG_WIND_MPS",
    ps.avg_prcp_cm          AS "AVG_PRCP_CM",
    tm.busiest_month        AS "BUSIEST_MONTH"
FROM pair_stats ps
JOIN top_month tm
  ON  ps.start_borough = tm.start_borough
  AND ps.start_neigh   = tm.start_neigh
  AND ps.end_borough   = tm.end_borough
  AND ps.end_neigh     = tm.end_neigh
ORDER BY ps.trips DESC NULLS LAST, ps.start_borough, ps.start_neigh;