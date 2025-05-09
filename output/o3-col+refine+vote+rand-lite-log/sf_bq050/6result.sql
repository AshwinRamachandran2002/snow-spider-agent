/* 2014 NYC bike-trip ↔ Central-Park weather analysis by start/end neighborhood */

WITH trips_2014 AS (          --------------------------------------------------
    SELECT  "tripduration",
            "starttime",
            "start_station_latitude"    AS st_lat,
            "start_station_longitude"   AS st_lon,
            "end_station_latitude"      AS en_lat,
            "end_station_longitude"     AS en_lon,
            TO_DATE( TO_TIMESTAMP("starttime" / 1e6) )                    AS ride_date,
            DATE_PART('month', TO_TIMESTAMP("starttime" / 1e6))           AS ride_month
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS"
    WHERE   "starttime" BETWEEN 1388577600000000     -- 2014-01-01 00:00:00
                              AND 1420113599000000 )  -- 2014-12-31 23:59:59

, wx_daily AS (              --------------------------------------------------
    SELECT  TO_DATE("year"||LPAD("mo",2,'0')||LPAD("da",2,'0'),'YYYYMMDD') AS wx_date,
            "temp"                                        AS tmp_f,
            NULLIF("wdsp",'999.9')::FLOAT                AS wnd_k,
            NULLIF("prcp",99.99)                         AS prc_in
    FROM    NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2014"
    WHERE   "wban" = '94728'
      AND   "stn"  IN ('725033','725053','999999') )

, trips_wx AS (              --------------------------------------------------
    SELECT  t.*,
            w.tmp_f,
            w.wnd_k,
            w.prc_in
    FROM    trips_2014 t
    JOIN    wx_daily  w
           ON w.wx_date = t.ride_date )

, start_geo AS (             --------------------------------------------------
    SELECT  t.*,
            c."neighborhood" AS start_neigh
    FROM    trips_wx                               t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"  z
           ON ST_WITHIN(
                  ST_MAKEPOINT(t.st_lon , t.st_lat),
                  TO_GEOGRAPHY(z."zip_code_geom"))
    JOIN    NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES"          c
           ON z."zip_code" = c."zip" )

, full_trip AS (             --------------------------------------------------
    SELECT  s.*,
            c2."neighborhood" AS end_neigh
    FROM    start_geo                              s
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES"  z2
           ON ST_WITHIN(
                  ST_MAKEPOINT(s.en_lon , s.en_lat),
                  TO_GEOGRAPHY(z2."zip_code_geom"))
    JOIN    NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES"          c2
           ON z2."zip_code" = c2."zip" )

, agg_core AS (             --------------------------------------------------
    SELECT  start_neigh,
            end_neigh,
            COUNT(*)                                AS trip_cnt,
            ROUND( AVG("tripduration")/60 , 1)      AS avg_minutes,
            ROUND( AVG(tmp_f)           , 1)        AS avg_temp_f,
            ROUND( AVG(wnd_k * 0.514444), 1)        AS avg_wind_ms,
            ROUND( AVG(prc_in * 2.54)   , 1)        AS avg_prcp_cm
    FROM    full_trip
    GROUP  BY 1,2 )

, month_hist AS (           --------------------------------------------------
    SELECT  start_neigh,
            end_neigh,
            ride_month,
            COUNT(*)  AS m_cnt
    FROM    full_trip
    GROUP  BY 1,2,3 )

, top_month AS (            --------------------------------------------------
    SELECT  start_neigh,
            end_neigh,
            ride_month AS busiest_month
    FROM   ( SELECT *,
                    ROW_NUMBER() OVER (PARTITION BY start_neigh, end_neigh
                                        ORDER BY m_cnt DESC) AS rn
             FROM   month_hist ) t
    WHERE  rn = 1 )

--================================================================-----------
SELECT  a.start_neigh    AS "start_neighborhood",
        a.end_neigh      AS "end_neighborhood",
        a.trip_cnt       AS "total_trips",
        a.avg_minutes    AS "avg_duration_min",
        a.avg_temp_f     AS "avg_temp_f",
        a.avg_wind_ms    AS "avg_wind_m_s",
        a.avg_prcp_cm    AS "avg_prcp_cm",
        tm.busiest_month AS "month_most_trips"
FROM    agg_core a
JOIN    top_month tm
      ON a.start_neigh = tm.start_neigh
     AND a.end_neigh   = tm.end_neigh
ORDER  BY a.trip_cnt DESC NULLS LAST;