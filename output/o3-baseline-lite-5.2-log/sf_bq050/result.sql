/* Citi Bike trips (2014) × ZIP polygons × Central Park weather
   Aggregated by start/end neighbourhood pairs                                      */

WITH
/* -------------------------------------------------------------------------- */
/* 1. 2014 Citi Bike trips (timestamps are µ‑seconds, already NYC local)       */
trips_2014 AS (
    SELECT  t.*,
            TO_DATE(TO_TIMESTAMP_NTZ("starttime" / 1e6))            AS trip_date,
            MONTH   (TO_TIMESTAMP_NTZ("starttime" / 1e6))           AS trip_month
    FROM    NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE."CITIBIKE_TRIPS" t
    WHERE   YEAR(TO_TIMESTAMP_NTZ("starttime" / 1e6)) = 2014
      AND   "start_station_longitude" IS NOT NULL
      AND   "end_station_longitude"   IS NOT NULL
),

/* -------------------------------------------------------------------------- */
/* 2. Map START coordinates → ZIP polygon → neighbourhood                      */
start_geo AS (
    SELECT  t.*,
            zs."zip_code"                                           AS start_zip
    FROM    trips_2014 t
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" zs
          ON ST_WITHIN(
                 ST_MAKEPOINT(t."start_station_longitude",
                               t."start_station_latitude"),
                 TO_GEOGRAPHY(zs."zip_code_geom"))
),
start_nbh AS (
    SELECT  sg.*,
            cz."neighborhood"                                       AS start_neighborhood
    FROM    start_geo sg
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" cz
           ON cz."zip" = TO_NUMBER(sg.start_zip)
),

/* -------------------------------------------------------------------------- */
/* 3. Map END coordinates → ZIP polygon → neighbourhood                        */
end_geo AS (
    SELECT  sn.*,
            ze."zip_code"                                           AS end_zip
    FROM    start_nbh sn
    JOIN    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES."ZIP_CODES" ze
          ON ST_WITHIN(
                 ST_MAKEPOINT(sn."end_station_longitude",
                               sn."end_station_latitude"),
                 TO_GEOGRAPHY(ze."zip_code_geom"))
),
trips_neigh AS (
    SELECT  eg.*,
            ce."neighborhood"                                       AS end_neighborhood
    FROM    end_geo eg
    LEFT JOIN NEW_YORK_CITIBIKE_1.CYCLISTIC."ZIP_CODES" ce
           ON ce."zip" = TO_NUMBER(eg.end_zip)
    WHERE   eg.start_neighborhood IS NOT NULL
      AND   ce."neighborhood"   IS NOT NULL
),

/* -------------------------------------------------------------------------- */
/* 4. Daily Central‑Park weather (USAF 725033 | WBAN 94728)                    */
weather_cp AS (
    SELECT  TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) AS weather_date,
            NULLIF("temp",  9999.9)                        AS temp_f,
            NULLIF(TRY_TO_DOUBLE("wdsp"), 999.9)           AS wdsp_knots,
            NULLIF("prcp",  99.99)                         AS prcp_in
    FROM    NEW_YORK_CITIBIKE_1.NOAA_GSOD."GSOD2014"
    WHERE   "stn" = '725033'  -- Central Park
      AND   "wban" = '94728'
),

/* -------------------------------------------------------------------------- */
/* 5. Attach same‑day weather to each trip                                     */
trips_wx AS (
    SELECT  tn.*,
            wx.temp_f,
            wx.wdsp_knots,
            wx.prcp_in
    FROM    trips_neigh tn
    LEFT JOIN weather_cp wx
           ON wx.weather_date = tn.trip_date
),

/* -------------------------------------------------------------------------- */
/* 6. Peak‑trip month per neighbourhood pair                                   */
peak_month AS (
    SELECT  start_neighborhood,
            end_neighborhood,
            trip_month                                   AS peak_month,
            ROW_NUMBER() OVER (PARTITION BY start_neighborhood,
                                             end_neighborhood
                               ORDER BY COUNT(*) DESC,
                                        trip_month)      AS rn
    FROM    trips_wx
    GROUP BY 1,2,3
)

/* -------------------------------------------------------------------------- */
/* 7. Final aggregation                                                        */
SELECT
    tw.start_neighborhood,
    tw.end_neighborhood,
    COUNT(*)                                          AS total_trips,
    ROUND(AVG(tw."tripduration") / 60, 1)             AS avg_trip_duration_min,
    ROUND(AVG(tw.temp_f), 1)                          AS avg_temp_f,
    ROUND(AVG(tw.wdsp_knots) * 0.514444 , 1)          AS avg_wind_ms,
    ROUND(AVG(tw.prcp_in)   * 2.54     , 1)           AS avg_prcp_cm,
    pm.peak_month
FROM        trips_wx tw
JOIN        peak_month pm
      ON    pm.start_neighborhood = tw.start_neighborhood
     AND    pm.end_neighborhood   = tw.end_neighborhood
     AND    pm.rn = 1
GROUP BY
    tw.start_neighborhood,
    tw.end_neighborhood,
    pm.peak_month
ORDER BY
    total_trips DESC NULLS LAST,
    tw.start_neighborhood,
    tw.end_neighborhood;