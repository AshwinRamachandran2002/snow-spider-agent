/*  NYC Citi Bike trips (2014) enriched with Central‑Park weather        */
/*  Aggregated by Origin / Destination neighbourhood (borough, hood)     */
/*  – Geospatial work done once on the ±1 k distinct station locations    */

WITH ---------------------------------------------------------------------
trips_2014 AS (      -- 2014 trips with useful typed fields
    SELECT
        t."tripduration" ,
        t."starttime" ,
        t."start_station_id"      AS start_id ,
        t."start_station_latitude"  AS start_lat ,
        t."start_station_longitude" AS start_lon ,
        t."end_station_id"        AS end_id ,
        t."end_station_latitude"    AS end_lat ,
        t."end_station_longitude"   AS end_lon ,
        DATE_TRUNC('DAY', TO_TIMESTAMP_LTZ(t."starttime"/1e6)) AS trip_date ,
        MONTH(TO_TIMESTAMP_LTZ(t."starttime"/1e6))             AS trip_month
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    WHERE YEAR(TO_TIMESTAMP_LTZ(t."starttime"/1e6)) = 2014
),

/* --------------------------------------------------------------------- */
station_points AS (  -- distinct station‑locations appearing in 2014
    SELECT DISTINCT
        start_id AS station_id ,
        start_lat AS lat ,
        start_lon AS lon
    FROM trips_2014
    WHERE start_lat IS NOT NULL AND start_lon IS NOT NULL

    UNION

    SELECT DISTINCT
        end_id   AS station_id ,
        end_lat  AS lat ,
        end_lon  AS lon
    FROM trips_2014
    WHERE end_lat IS NOT NULL AND end_lon IS NOT NULL
),

station_zip AS (     -- map each station point to a ZIP (cheap: ~1 k rows)
    SELECT
        sp.station_id ,
        z."zip_code"                                                     AS zip_code
    FROM station_points sp
    JOIN NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
      ON ST_WITHIN(
            ST_POINT(sp.lon , sp.lat) ,
            TO_GEOGRAPHY(z."zip_code_geom")
         )
),

station_neigh AS (   -- translate ZIP → borough / neighbourhood
    SELECT
        sz.station_id ,
        c."borough"      ,
        c."neighborhood"
    FROM station_zip sz
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES c
           ON c."zip" = TRY_TO_NUMBER(sz.zip_code)
),

/* --------------------------------------------------------------------- */
trips_located AS (   -- bring names back to every trip row
    SELECT
        t.* ,
        sn_start."borough"      AS start_borough ,
        sn_start."neighborhood" AS start_neighborhood ,
        sn_end."borough"        AS end_borough ,
        sn_end."neighborhood"   AS end_neighborhood
    FROM trips_2014 t
    LEFT JOIN station_neigh sn_start ON sn_start.station_id = t.start_id
    LEFT JOIN station_neigh sn_end   ON sn_end.station_id   = t.end_id
),

/* --------------------------------------------------------------------- */
cp_station AS (      -- Central‑Park weather station (latest record)
    SELECT "usaf" AS usaf , "wban"
    FROM (
        SELECT DISTINCT "usaf" , "wban" , "end"
        FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.STATIONS
        WHERE UPPER("name") LIKE '%CENTRAL PARK%'
        ORDER BY "end" DESC
        LIMIT 1
    )
),

weather AS (         -- Central‑Park daily weather for 2014
    SELECT
        DATE_FROM_PARTS(TO_NUMBER(g."year"),TO_NUMBER(g."mo"),TO_NUMBER(g."da")) AS wx_date ,
        TO_NUMBER(g."temp")  AS temp_f ,
        TO_NUMBER(g."wdsp")  AS wdsp_knots ,
        TO_NUMBER(g."prcp")  AS prcp_in
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014 g
    JOIN cp_station s
      ON g."stn"  = s.usaf
     AND g."wban" = s."wban"
),

trips_weather AS (   -- attach same‑day weather
    SELECT
        tl.* ,
        w.temp_f ,
        w.wdsp_knots ,
        w.prcp_in
    FROM trips_located tl
    LEFT JOIN weather w
           ON tl.trip_date = w.wx_date
),

/* --------------------------------------------------------------------- */
month_counts AS (    -- trips per OD‑pair per month
    SELECT
        start_neighborhood ,
        end_neighborhood ,
        trip_month ,
        COUNT(*) AS cnt
    FROM trips_weather
    GROUP BY start_neighborhood , end_neighborhood , trip_month
),

peak_month AS (      -- month with max trips (ties -> smaller month number)
    SELECT
        start_neighborhood ,
        end_neighborhood ,
        trip_month
    FROM (
        SELECT m.* ,
               ROW_NUMBER() OVER (PARTITION BY start_neighborhood , end_neighborhood
                                  ORDER BY cnt DESC , trip_month) AS rn
        FROM month_counts m
    )
    WHERE rn = 1
),

/* --------------------------------------------------------------------- */
agg AS (
    SELECT
        start_neighborhood ,
        end_neighborhood ,
        COUNT(*)                                               AS total_trips ,
        ROUND(AVG("tripduration")/60 , 1)                      AS avg_trip_minutes ,
        ROUND(AVG(temp_f) , 1)                                 AS avg_temp_f ,
        ROUND(AVG(CASE WHEN wdsp_knots < 999 THEN wdsp_knots*0.514444 END) , 1) AS avg_wind_mps ,
        ROUND(AVG(CASE WHEN prcp_in   <  99 THEN prcp_in*2.54  END) , 1)        AS avg_prcp_cm
    FROM trips_weather
    GROUP BY start_neighborhood , end_neighborhood
)

/* --------------------------------------------------------------------- */
SELECT
    a.start_neighborhood ,
    a.end_neighborhood ,
    a.total_trips ,
    a.avg_trip_minutes ,
    a.avg_temp_f ,
    a.avg_wind_mps ,
    a.avg_prcp_cm ,
    p.trip_month AS peak_month
FROM agg a
LEFT JOIN peak_month p
  ON p.start_neighborhood = a.start_neighborhood
 AND p.end_neighborhood   = a.end_neighborhood
ORDER BY a.total_trips DESC NULLS LAST ,
         a.start_neighborhood ,
         a.end_neighborhood;