/* Weather-adjusted Citi Bike flows (2014) between NYC neighbourhoods */
WITH trips_2014 AS (                     -- ➊ trips in calendar-year 2014
    SELECT
        "tripduration",
        "start_station_latitude"  AS start_lat,
        "start_station_longitude" AS start_lon,
        "end_station_latitude"    AS end_lat,
        "end_station_longitude"   AS end_lon,
        TO_TIMESTAMP_LTZ("starttime"/1e6)        AS start_ts
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE TO_CHAR(TO_TIMESTAMP_LTZ("starttime"/1e6),'YYYY') = '2014'
),
trip_points AS (                         -- ➋ add geometry + date parts
    SELECT
        t.*,
        ST_POINT(start_lon , start_lat)  AS start_geom,
        ST_POINT(end_lon   , end_lat  )  AS end_geom,
        TO_DATE(start_ts)                AS trip_date,
        TO_NUMBER(TO_CHAR(start_ts,'MM')) AS trip_month,
        ("tripduration"/60.0)            AS trip_min
    FROM trips_2014 t
),
with_start_zip AS (                      -- ➌ START point → ZIP polygon
    SELECT
        p.*,
        z."zip_code" AS start_zip
    FROM trip_points p
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
      ON ST_WITHIN(p.start_geom , TO_GEOGRAPHY(z."zip_code_geom"))
),
with_both_zips AS (                      -- ➍ END point → ZIP polygon
    SELECT
        s.*,
        z2."zip_code" AS end_zip
    FROM with_start_zip s
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z2
      ON ST_WITHIN(s.end_geom , TO_GEOGRAPHY(z2."zip_code_geom"))
),
with_neigh AS (                          -- ➎ attach borough / neighbourhood
    SELECT
        b.*,
        cz_s."borough"      AS start_borough,
        cz_s."neighborhood" AS start_neigh,
        cz_e."borough"      AS end_borough,
        cz_e."neighborhood" AS end_neigh
    FROM with_both_zips b
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cz_s
         ON cz_s."zip" = TO_NUMBER(b.start_zip)
    JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cz_e
         ON cz_e."zip" = TO_NUMBER(b.end_zip)
),
weather AS (                             -- ➏ Central-Park daily weather (GSOD)
    SELECT
        TO_DATE(CONCAT_WS('-', "year", LPAD("mo",2,'0'), LPAD("da",2,'0'))) AS wx_date,
        CAST("temp" AS FLOAT)                 AS temp_f,
        CAST("wdsp" AS FLOAT) * 0.514444      AS wind_ms,   -- knots → m/s
        CAST("prcp" AS FLOAT) * 2.54          AS prcp_cm    -- inches → cm
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014
    WHERE "stn" = '725033'  AND "wban" = '94728'            -- Central Park
),
trips_wx AS (                            -- ➐ merge trips with weather by date
    SELECT
        n.*,
        wx.temp_f,
        wx.wind_ms,
        wx.prcp_cm
    FROM with_neigh n
    LEFT JOIN weather wx
           ON wx.wx_date = n.trip_date
)
/* ➑ FINAL AGGREGATION */
SELECT
    start_borough || ' - ' || start_neigh  AS start_neighborhood,
    end_borough   || ' - ' || end_neigh    AS end_neighborhood,
    COUNT(*)                                AS total_trips,
    ROUND(AVG(trip_min) ,1)                AS avg_duration_minutes,
    ROUND(AVG(temp_f)   ,1)                AS avg_temp_f,
    ROUND(AVG(wind_ms)  ,1)                AS avg_wind_ms,
    ROUND(AVG(prcp_cm)  ,1)                AS avg_prcp_cm,
    MODE(trip_month)                       AS peak_month
FROM trips_wx
GROUP BY
    start_borough, start_neigh,
    end_borough,   end_neigh
ORDER BY total_trips DESC NULLS LAST;