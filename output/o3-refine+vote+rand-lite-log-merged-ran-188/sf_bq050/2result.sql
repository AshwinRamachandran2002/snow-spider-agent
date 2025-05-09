/*  Bike-trips 2014  ×  Central-Park weather (NYC)
    –– neighbourhood-to-neighbourhood flow metrics  ------------------------ */

WITH
/* -------------------------------------------------------------------- 1 */
/* 2014 trip universe (micro-second epoch → DATE, MONTH)                 */
trips_2014 AS (
    SELECT
        t."tripduration",
        t."start_station_latitude"    AS start_lat,
        t."start_station_longitude"   AS start_lon,
        t."end_station_latitude"      AS end_lat,
        t."end_station_longitude"     AS end_lon,
        /* convert micro-seconds since 1970-01-01 to DATE in NYC time zone */
        CONVERT_TIMEZONE(
             'America/New_York',
             DATEADD( SECOND, t."starttime" / 1000000 , '1970-01-01')
        ) :: DATE                                                   AS trip_date,
        MONTH( CONVERT_TIMEZONE(
             'America/New_York',
             DATEADD( SECOND, t."starttime" / 1000000 , '1970-01-01')))       AS trip_month
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    WHERE t."starttime"
          BETWEEN 1388534400000000         /* 2014-01-01 00:00:00 */
              AND 1420070399999999         /* 2014-12-31 23:59:59 */
),
/* -------------------------------------------------------------------- 2 */
/* attach ZIP polygons (start & end) and label them with borough / n'hood */
geo_start AS (
    SELECT
        tr.*,
        czs."borough"      AS start_borough,
        czs."neighborhood" AS start_neigh
    FROM trips_2014 tr
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES zp
      ON ST_WITHIN(
            TO_GEOGRAPHY('POINT(' || tr.start_lon || ' ' || tr.start_lat || ')'),
            ST_GEOGFROMWKB(zp."zip_code_geom"))
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES czs
      ON czs."zip" = zp."zip_code"
),
geo_both AS (
    SELECT
        gs.*,
        cze."borough"      AS end_borough,
        cze."neighborhood" AS end_neigh
    FROM geo_start gs
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES zp
      ON ST_WITHIN(
            TO_GEOGRAPHY('POINT(' || gs.end_lon || ' ' || gs.end_lat || ')'),
            ST_GEOGFROMWKB(zp."zip_code_geom"))
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cze
      ON cze."zip" = zp."zip_code"
),
/* -------------------------------------------------------------------- 3 */
/* Central-Park daily weather for 2014                                   */
weather_cp AS (
    SELECT
        TO_DATE("year"   || '-' ||
                LPAD("mo",2,'0') || '-' ||
                LPAD("da",2,'0') )                              AS wx_date,
        NULLIF("temp" , 9999.9)                                 AS temp_f,
        NULLIF(TRY_TO_DOUBLE("wdsp"), 999.9)                    AS wdsp_knots,
        NULLIF("prcp" , 99.99)                                  AS prcp_in
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014
    WHERE "stn" = '725033'  /* NYC Central Park station */
),
/* -------------------------------------------------------------------- 4 */
/* trips enriched with weather                                           */
enriched AS (
    SELECT
        g.start_borough, g.start_neigh,
        g.end_borough,   g.end_neigh,
        g.trip_month,
        g."tripduration",
        wx.temp_f,
        wx.wdsp_knots,
        wx.prcp_in
    FROM  geo_both  g
    LEFT JOIN weather_cp wx
           ON wx.wx_date = g.trip_date
),
/* -------------------------------------------------------------------- 5 */
/* month-level counts per neighbourhood pair                             */
month_counts AS (
    SELECT
        start_neigh, end_neigh, trip_month,
        COUNT(*) AS month_trip_cnt
    FROM enriched
    GROUP BY 1,2,3
),
/* pick the month with the most trips for each pair                      */
month_ranked AS (
    SELECT
        start_neigh, end_neigh, trip_month,
        ROW_NUMBER() OVER (PARTITION BY start_neigh, end_neigh
                           ORDER BY month_trip_cnt DESC, trip_month) AS rn
    FROM month_counts
)
/* -------------------------------------------------------------------- 6 */
/* final aggregation                                                     */
SELECT
    e.start_neigh,
    e.end_neigh,
    COUNT(*)                                           AS trip_cnt,
    ROUND(AVG(e."tripduration")/60, 1)                 AS avg_dur_min,
    ROUND(AVG(e.temp_f) , 1)                           AS avg_temp_f,
    ROUND(AVG(e.wdsp_knots)*0.5144 , 1)                AS avg_wind_mps,
    ROUND(AVG(e.prcp_in) * 2.54 , 1)                   AS avg_prcp_cm,
    MIN(CASE WHEN m.rn = 1 THEN m.trip_month END)      AS peak_month
FROM         enriched       e
LEFT JOIN    month_ranked   m
       ON    e.start_neigh = m.start_neigh
      AND    e.end_neigh   = m.end_neigh
GROUP BY
    e.start_neigh,
    e.end_neigh
ORDER BY trip_cnt DESC NULLS LAST;