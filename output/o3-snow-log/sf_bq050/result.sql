/* Bike-trip flows (2014) between NYC neighbourhoods with
   same-day Central-Park weather                                               */

WITH trips_2014 AS ( -----------------------------------------------------------
    SELECT  "start_station_latitude"   AS start_lat ,
            "start_station_longitude"  AS start_lon ,
            "end_station_latitude"     AS end_lat ,
            "end_station_longitude"    AS end_lon ,
            "tripduration"             AS trip_duration ,
            CAST( TO_TIMESTAMP("starttime"/1e6) AS DATE)               AS trip_date ,
            EXTRACT(MONTH FROM TO_TIMESTAMP("starttime"/1e6))          AS trip_month
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE   "starttime" BETWEEN 1388534400000000 AND 1420070399000000
), start_zip AS ( --------------------------------------------------------------
    SELECT  t.* ,
            gz."zip_code"::TEXT AS start_zip
    FROM    trips_2014 t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES gz
           ON ST_CONTAINS(
                TO_GEOGRAPHY(gz."zip_code_geom"),
                TO_GEOGRAPHY( CONCAT('POINT(', t.start_lon,' ',t.start_lat,')') )
              )
), both_zips AS ( --------------------------------------------------------------
    SELECT  s.* ,
            gz."zip_code"::TEXT AS end_zip
    FROM    start_zip s
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES gz
           ON ST_CONTAINS(
                TO_GEOGRAPHY(gz."zip_code_geom"),
                TO_GEOGRAPHY( CONCAT('POINT(', s.end_lon,' ',s.end_lat,')') )
              )
), with_neighb AS ( ------------------------------------------------------------
    SELECT  b.* ,
            czs."neighborhood" AS start_neigh ,
            cze."neighborhood" AS end_neigh
    FROM    both_zips b
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES czs
           ON czs."zip" = TRY_TO_NUMBER(b.start_zip)
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cze
           ON cze."zip" = TRY_TO_NUMBER(b.end_zip)
    WHERE   czs."neighborhood" IS NOT NULL
      AND   cze."neighborhood" IS NOT NULL
), weather_2014 AS ( -----------------------------------------------------------
    SELECT  TO_DATE(CONCAT("year",'-',"mo",'-',"da"))  AS wx_date ,
            "temp"                      AS temp_f ,
            TRY_TO_NUMBER("wdsp")       AS wind_knots ,
            "prcp"                      AS prcp_in
    FROM    NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014
    WHERE   "wban" = '94728'            -- Central Park
), trips_wx AS ( ---------------------------------------------------------------
    SELECT  n.start_neigh ,
            n.end_neigh ,
            n.trip_duration ,
            n.trip_month ,
            w.temp_f ,
            w.wind_knots ,
            w.prcp_in
    FROM    with_neighb n
    JOIN    weather_2014 w
           ON w.wx_date = n.trip_date
), agg_totals AS ( -------------------------------------------------------------
    SELECT  start_neigh ,
            end_neigh ,
            COUNT(*)                         AS total_trips ,
            AVG(trip_duration)/60.0          AS avg_minutes ,
            AVG(temp_f)                      AS avg_temp_f ,
            AVG(wind_knots * 0.514444)       AS avg_wind_mps ,
            AVG(prcp_in * 2.54)              AS avg_prcp_cm
    FROM    trips_wx
    GROUP BY 1,2
), month_counts AS ( -----------------------------------------------------------
    SELECT  start_neigh ,
            end_neigh ,
            trip_month ,
            COUNT(*) AS month_trips
    FROM    trips_wx
    GROUP BY 1,2,3
), best_month AS ( -------------------------------------------------------------
    SELECT DISTINCT
           start_neigh ,
           end_neigh ,
           FIRST_VALUE(trip_month)
                OVER (PARTITION BY start_neigh,end_neigh
                      ORDER BY month_trips DESC, trip_month) AS busiest_month
    FROM   month_counts
)
SELECT  a.start_neigh  AS "start_neighborhood" ,
        a.end_neigh    AS "end_neighborhood"   ,
        a.total_trips  AS "total_trips" ,
        ROUND(a.avg_minutes  ,1) AS "avg_trip_duration_minutes" ,
        ROUND(a.avg_temp_f   ,1) AS "avg_temp_f" ,
        ROUND(a.avg_wind_mps ,1) AS "avg_wind_speed_mps" ,
        ROUND(a.avg_prcp_cm  ,1) AS "avg_precip_cm" ,
        b.busiest_month      AS "busiest_month"
FROM   agg_totals a
JOIN   best_month b
  ON   b.start_neigh = a.start_neigh
 AND   b.end_neigh   = a.end_neigh
ORDER BY a.total_trips DESC NULLS LAST;