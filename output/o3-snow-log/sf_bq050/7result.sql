/* =======================================================================
   Weather-adjusted Citi Bike flows between NYC neighbourhoods – year 2014
   ‑- tuned to finish within Snowflake’s default 200-second time-out
   ======================================================================= */
WITH
/* -----------------------------------------------------------------------
   1.  Daily Central-Park weather (WBAN 94728) for calendar-year 2014
   ----------------------------------------------------------------------- */
weather AS (
    SELECT
        TO_DATE(CONCAT_WS('-', "year", LPAD("mo",2,'0'), LPAD("da",2,'0'))) AS weather_day ,
        CAST("temp" AS FLOAT)                         AS temp_f ,
        CAST("wdsp" AS FLOAT) * 0.514444              AS wind_mps ,      -- knots → m s-¹
        CAST("prcp" AS FLOAT) * 2.54                 AS prcp_cm          -- inches → cm
    FROM NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014
    WHERE "wban" = '94728'
),

/* -----------------------------------------------------------------------
   2.  NYC ZIP-code polygons only (keeps spatial join small)
   ----------------------------------------------------------------------- */
zip_geo AS (
    SELECT
        TO_NUMBER("zip_code")         AS zip ,
        TO_GEOGRAPHY("zip_code_geom") AS geom
    FROM NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES
    WHERE "state_code" = 'NY'                       -- restrict to NY-state ZIPs
),

/* -----------------------------------------------------------------------
   3.  Citi Bike trips that BOTH start & end inside a coarse NYC bounding box
       (≈ 40–41 °N , -75 – ‑73 °E) and whose start-timestamp is in 2014
   ----------------------------------------------------------------------- */
trips_2014 AS (
    SELECT
        t."tripduration"                           ,
        t."start_station_latitude"  AS s_lat ,
        t."start_station_longitude" AS s_lon ,
        t."end_station_latitude"    AS e_lat ,
        t."end_station_longitude"   AS e_lon ,
        TO_TIMESTAMP_LTZ(t."starttime" / 1e6) AS ts_start
    FROM NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    WHERE   t."start_station_latitude"  BETWEEN 40.0 AND 41.0
      AND   t."end_station_latitude"    BETWEEN 40.0 AND 41.0
      AND   t."start_station_longitude" BETWEEN -75.0 AND -73.0
      AND   t."end_station_longitude"   BETWEEN -75.0 AND -73.0
      AND   ts_start >= '2014-01-01'
      AND   ts_start <  '2015-01-01'
),

/* -----------------------------------------------------------------------
   4.  Point-in-polygon to fetch start / end ZIP codes
       – spatial join is now limited to NY ZIPs and filtered trips only
   ----------------------------------------------------------------------- */
trip_zips AS (
    SELECT
        tr.* ,
        sz.zip AS start_zip ,
        ez.zip AS end_zip
    FROM trips_2014 tr
    LEFT JOIN zip_geo sz
           ON ST_CONTAINS(
                  sz.geom ,
                  TO_GEOGRAPHY('POINT('||tr.s_lon||' '||tr.s_lat||')')
              )
    LEFT JOIN zip_geo ez
           ON ST_CONTAINS(
                  ez.geom ,
                  TO_GEOGRAPHY('POINT('||tr.e_lon||' '||tr.e_lat||')')
              )
),

/* -----------------------------------------------------------------------
   5.  Map ZIPs → borough & neighbourhood via Cyclistic lookup
   ----------------------------------------------------------------------- */
trip_neigh AS (
    SELECT
        tz.* ,
        sb."borough"      AS start_borough ,
        sb."neighborhood" AS start_neighborhood ,
        eb."borough"      AS end_borough ,
        eb."neighborhood" AS end_neighborhood
    FROM trip_zips tz
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES sb
           ON sb."zip" = tz.start_zip
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES eb
           ON eb."zip" = tz.end_zip
    WHERE sb."borough" IS NOT NULL                     -- discard trips we couldn’t geo-tag
      AND eb."borough" IS NOT NULL
),

/* -----------------------------------------------------------------------
   6.  Attach weather + derive calendar day & month
   ----------------------------------------------------------------------- */
trip_weather AS (
    SELECT
        tn.* ,
        w.temp_f ,
        w.wind_mps ,
        w.prcp_cm ,
        DATE(tn.ts_start)  AS trip_day ,
        MONTH(tn.ts_start) AS trip_month
    FROM trip_neigh tn
    INNER JOIN weather w                -- inner join: day is guaranteed in 2014 set
            ON w.weather_day = DATE(tn.ts_start)
),

/* -----------------------------------------------------------------------
   7.  Monthly trip counts per neighbourhood pair
   ----------------------------------------------------------------------- */
month_counts AS (
    SELECT
        start_borough , start_neighborhood ,
        end_borough   , end_neighborhood   ,
        trip_month ,
        COUNT(*) AS trips_in_month
    FROM trip_weather
    GROUP BY 1,2,3,4,5
),

/* -----------------------------------------------------------------------
   8.  Determine the month with the most trips for each pair
   ----------------------------------------------------------------------- */
peak_month AS (
    SELECT
        start_borough , start_neighborhood ,
        end_borough   , end_neighborhood ,
        trip_month      AS peak_month ,
        ROW_NUMBER() OVER (
            PARTITION BY start_borough , start_neighborhood ,
                         end_borough   , end_neighborhood
            ORDER BY trips_in_month DESC
        ) AS rn
    FROM month_counts
)

/* -----------------------------------------------------------------------
   9.  Final metrics
   ----------------------------------------------------------------------- */
SELECT
    tw.start_borough      ,
    tw.start_neighborhood ,
    tw.end_borough        ,
    tw.end_neighborhood   ,
    COUNT(*)                                AS total_trips ,
    ROUND(AVG(tw."tripduration") / 60 , 1)  AS avg_trip_minutes ,
    ROUND(AVG(tw.temp_f)   , 1)             AS avg_temp_f ,
    ROUND(AVG(tw.wind_mps) , 1)             AS avg_wind_mps ,
    ROUND(AVG(tw.prcp_cm)  , 1)             AS avg_prcp_cm ,
    pm.peak_month
FROM   trip_weather tw
LEFT JOIN peak_month pm
       ON  pm.start_borough      = tw.start_borough
       AND pm.start_neighborhood = tw.start_neighborhood
       AND pm.end_borough        = tw.end_borough
       AND pm.end_neighborhood   = tw.end_neighborhood
       AND pm.rn = 1
GROUP BY
    tw.start_borough ,
    tw.start_neighborhood ,
    tw.end_borough ,
    tw.end_neighborhood ,
    pm.peak_month
ORDER BY total_trips DESC NULLS LAST;