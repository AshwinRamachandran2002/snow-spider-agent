/*  Neighborhood‑to‑Neighborhood Citi‑Bike flow (2014) enriched with Central‑Park
    weather.  Requires GEOGRAPHY entitlement in Snowflake.                            */

WITH trips_2014 AS (  ---------------------------------- 1. raw trips for 2014
    SELECT
        /* geometry points for quick re‑use */
        TO_GEOGRAPHY('POINT('||"start_station_longitude"||' '||"start_station_latitude"||')') AS g_start ,
        TO_GEOGRAPHY('POINT('||"end_station_longitude"  ||' '||"end_station_latitude"  ||')') AS g_end   ,
        "tripduration" / 60.0                                                                AS duration_min ,
        TO_DATE( TO_TIMESTAMP_NTZ("starttime" / 1000000) )                                    AS trip_date    ,
        EXTRACT(MONTH FROM TO_TIMESTAMP_NTZ("starttime" / 1000000))::INT                      AS trip_month
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS
    WHERE "starttime" BETWEEN 1388534400000000   /* 2014‑01‑01 00:00:00 */
                        AND     1420070399000000 /* 2014‑12‑31 23:59:59 */
),                                                         

weather_2014 AS (  --------------------------------------- 2. daily weather (Central Park)
    SELECT
        TO_DATE(TO_DATE("year"||'-'||"mo"||'-'||"da"))                                   AS trip_date ,
        AVG( NULLIF("temp" ,9999.9)                       )                             AS temp_f ,
        AVG( NULLIF(TRY_TO_NUMBER("wdsp") ,999.9) * 0.514444 )                          AS wdsp_ms ,
        AVG( CASE WHEN "prcp" = 99.99 THEN NULL ELSE "prcp"*2.54 END )                  AS prcp_cm
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014
    WHERE "stn" = '725033'       -- Central Park weather‑station (USA F = 725033 / WBAN 94728)
    GROUP BY trip_date
),                                                         

---------------------------------------------------------------------------
-- 3. map every trip point to the ZIP polygon it falls inside
---------------------------------------------------------------------------
start_zips AS (
    SELECT  t.* ,
            z."zip_code" AS start_zip
    FROM    trips_2014                t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
           ON ST_WITHIN(t.g_start , TO_GEOGRAPHY(z."zip_code_geom"))
),
both_zips AS (
    SELECT  s.* ,
            z."zip_code" AS end_zip
    FROM    start_zips                       s
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
           ON ST_WITHIN(s.g_end , TO_GEOGRAPHY(z."zip_code_geom"))
),

---------------------------------------------------------------------------
-- 4. attach borough / neighborhood names (Cyclistic helper table)
---------------------------------------------------------------------------
with_neighborhoods AS (
    SELECT
        cb."borough"      AS start_borough ,
        cb."neighborhood" AS start_neighborhood ,
        ce."borough"      AS end_borough   ,
        ce."neighborhood" AS end_neighborhood ,
        b.duration_min ,
        b.trip_date ,
        b.trip_month
    FROM  both_zips b
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES cb  ON cb."zip" = b.start_zip
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES ce  ON ce."zip" = b.end_zip
    WHERE cb."neighborhood" IS NOT NULL   -- keep only trips we can label
      AND ce."neighborhood" IS NOT NULL
),

---------------------------------------------------------------------------
-- 5. merge with weather for the start‑date of each trip
---------------------------------------------------------------------------
trips_weather AS (
    SELECT  n.* ,
            w.temp_f ,
            w.wdsp_ms ,
            w.prcp_cm
    FROM    with_neighborhoods n
    LEFT  JOIN weather_2014   w  USING (trip_date)
),

---------------------------------------------------------------------------
-- 6‑a.  main aggregations
---------------------------------------------------------------------------
agg AS (
    SELECT
        start_borough ,
        start_neighborhood ,
        end_borough ,
        end_neighborhood ,
        COUNT(*)                               AS total_trips ,
        ROUND( AVG(duration_min) ,1)           AS avg_duration_min ,
        ROUND( AVG(temp_f)      ,1)            AS avg_temp_f ,
        ROUND( AVG(wdsp_ms)     ,1)            AS avg_wind_ms ,
        ROUND( AVG(prcp_cm)     ,1)            AS avg_prcp_cm
    FROM trips_weather
    GROUP BY 1,2,3,4
),

---------------------------------------------------------------------------
-- 6‑b.  find the month with most trips per neighbourhood‑pair
---------------------------------------------------------------------------
month_rank AS (
    SELECT
        start_borough ,
        start_neighborhood ,
        end_borough ,
        end_neighborhood ,
        trip_month ,
        COUNT(*)                               AS trip_cnt ,
        ROW_NUMBER() OVER (
            PARTITION BY start_borough,start_neighborhood,end_borough,end_neighborhood
            ORDER BY COUNT(*) DESC, trip_month          -- tie‑break: earliest month
        ) AS rn
    FROM with_neighborhoods
    GROUP BY 1,2,3,4,5
)

---------------------------------------------------------------------------
-- 7. final result
---------------------------------------------------------------------------
SELECT
    a.start_borough      ,
    a.start_neighborhood ,
    a.end_borough        ,
    a.end_neighborhood   ,
    a.total_trips        ,
    a.avg_duration_min   ,
    a.avg_temp_f         ,
    a.avg_wind_ms        ,
    a.avg_prcp_cm        ,
    m.trip_month         AS month_most_trips
FROM      agg         a
JOIN      month_rank  m
  ON  m.start_borough      = a.start_borough
  AND m.start_neighborhood = a.start_neighborhood
  AND m.end_borough        = a.end_borough
  AND m.end_neighborhood   = a.end_neighborhood
  AND m.rn = 1                      -- top month only
ORDER BY a.total_trips DESC NULLS LAST;