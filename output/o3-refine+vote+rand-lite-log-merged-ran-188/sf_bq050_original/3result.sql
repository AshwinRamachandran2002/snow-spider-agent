/*  NYC Citi Bike trips × Central‑Park weather   –   calendar‑year 2018  */

WITH trips_2018 AS (      /* 1️⃣  restrict to rides that started in 2018 */
    SELECT
        TO_TIMESTAMP_NTZ("starttime"/1e6)                    AS start_ts ,          -- µs → sec
        DATE_TRUNC('DAY', TO_TIMESTAMP_NTZ("starttime"/1e6)) AS trip_date ,
        MONTH(TO_TIMESTAMP_NTZ("starttime"/1e6))             AS trip_month ,
        "tripduration"                                       AS trip_sec ,
        "start_station_latitude"   AS start_lat ,
        "start_station_longitude"  AS start_lon ,
        "end_station_latitude"     AS end_lat ,
        "end_station_longitude"    AS end_lon
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE DATE_PART(year , TO_TIMESTAMP_NTZ("starttime"/1e6)) = 2018
),

/* 2️⃣  build GEOGRAPHY points for spatial joins */
geo_pts AS (
    SELECT
        t.* ,
        TO_GEOGRAPHY('POINT('||start_lon||' '||start_lat||')') AS start_geo ,
        TO_GEOGRAPHY('POINT('||end_lon  ||' '||end_lat  ||')') AS end_geo
    FROM trips_2018 t
),

/* 3️⃣  attach ZIP codes (ZIP polygons stored as WKB; cast → GEOGRAPHY) */
zipped AS (
    SELECT
        g.* ,
        z1."zip_code" AS start_zip ,
        z2."zip_code" AS end_zip
    FROM geo_pts g
    LEFT JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z1
           ON ST_WITHIN(g.start_geo , TO_GEOGRAPHY(z1."zip_code_geom"))
    LEFT JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z2
           ON ST_WITHIN(g.end_geo   , TO_GEOGRAPHY(z2."zip_code_geom"))
),

/* 4️⃣  map ZIP → borough / neighbourhood (Cyclistic table)            */
with_neigh AS (
    SELECT
        z.* ,
        s."borough"      AS start_borough      ,
        s."neighborhood" AS start_neighborhood ,
        e."borough"      AS end_borough        ,
        e."neighborhood" AS end_neighborhood
    FROM zipped z
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES s
           ON s."zip" = TRY_TO_NUMBER(z.start_zip)
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES e
           ON e."zip" = TRY_TO_NUMBER(z.end_zip)
    WHERE s."neighborhood" IS NOT NULL
      AND e."neighborhood" IS NOT NULL
),

/* 5️⃣  Central‑Park daily weather for 2018 (USAF 725033 / WBAN 94728)  */
wx AS (
    SELECT
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) AS wx_date ,
        "temp"                           AS temp_f ,
        TRY_TO_NUMBER("wdsp")            AS wind_knots ,
        "prcp"                           AS prcp_in
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2018
    WHERE "stn" = '725033' AND "wban" = '94728'
),

/* 6️⃣  join rides to same‑day weather (LEFT JOIN to keep all rides)    */
rides_wx AS (
    SELECT
        n.* ,
        wx.temp_f ,
        wx.wind_knots ,
        wx.prcp_in
    FROM with_neigh n
    LEFT JOIN wx ON n.trip_date = wx.wx_date
),

/* 7️⃣  busiest month per neighbourhood‑pair                           */
month_counts AS (
    SELECT
        start_borough , start_neighborhood ,
        end_borough   , end_neighborhood   ,
        trip_month ,
        COUNT(*) AS trips_in_month
    FROM rides_wx
    GROUP BY 1,2,3,4,5
),
busiest_month AS (
    SELECT *
    FROM (
        SELECT
            mc.* ,
            ROW_NUMBER() OVER (
                PARTITION BY start_borough, start_neighborhood,
                             end_borough  , end_neighborhood
                ORDER BY trips_in_month DESC , trip_month
            ) AS rn
        FROM month_counts mc
    )
    WHERE rn = 1
),

/* 8️⃣  aggregate metrics                                              */
agg AS (
    SELECT
        rw.start_borough      ,
        rw.start_neighborhood ,
        rw.end_borough        ,
        rw.end_neighborhood   ,

        COUNT(*)                                   AS total_trips ,
        ROUND(AVG(rw.trip_sec) / 60        , 1)    AS avg_trip_minutes ,
        ROUND(AVG(rw.temp_f)               , 1)    AS avg_temperature_f ,
        ROUND(AVG(COALESCE(rw.wind_knots,0)*0.514444) , 1) AS avg_wind_mps ,
        ROUND(AVG(COALESCE(rw.prcp_in ,0)*2.54)       , 1) AS avg_prcp_cm
    FROM rides_wx rw
    GROUP BY 1,2,3,4
)

/* 9️⃣  final report                                                   */
SELECT
    a.start_borough ,
    a.start_neighborhood ,
    a.end_borough   ,
    a.end_neighborhood ,
    a.total_trips ,
    a.avg_trip_minutes ,
    a.avg_temperature_f ,
    a.avg_wind_mps ,
    a.avg_prcp_cm ,
    bm.trip_month AS busiest_month
FROM agg a
JOIN busiest_month bm
  ON  a.start_borough      = bm.start_borough
  AND a.start_neighborhood = bm.start_neighborhood
  AND a.end_borough        = bm.end_borough
  AND a.end_neighborhood   = bm.end_neighborhood
ORDER BY a.total_trips DESC NULLS LAST,
         a.start_borough,
         a.start_neighborhood;