WITH trips_2014 AS (  -- Citi Bike rides that started in calendar-year 2014
    SELECT  *,
            TO_DATE( TO_TIMESTAMP_NTZ("starttime" / 1e6) )        AS trip_date,
            MONTH  ( TO_TIMESTAMP_NTZ("starttime" / 1e6) )        AS trip_month
    FROM    "NEW_YORK_CITIBIKE_1"."NEW_YORK_CITIBIKE"."CITIBIKE_TRIPS"
    WHERE   "starttime" BETWEEN 1388534400000000     -- 2014-01-01
                         AND     1420070399000000     -- 2014-12-31
),

/* NY-state ZIP-code polygons -------------------------------------*/
geo_zip AS (
    SELECT  "zip_code",
            TO_GEOGRAPHY("zip_code_geom") AS zip_geom
    FROM    "NEW_YORK_CITIBIKE_1"."GEO_US_BOUNDARIES"."ZIP_CODES"
    WHERE   "state_code" = 'NY'
),

/* ZIP → neighbourhood lookup -------------------------------------*/
neigh_lu AS (
    SELECT  "zip"          AS zip_code,
            "neighborhood" AS neighborhood
    FROM    "NEW_YORK_CITIBIKE_1"."CYCLISTIC"."ZIP_CODES"
),

/* Attach start / end ZIP codes to each trip ----------------------*/
trip_zips AS (
    SELECT  t.*,
            sz."zip_code" AS start_zip,
            ez."zip_code" AS end_zip
    FROM    trips_2014 t
    /* start ZIP */
    LEFT JOIN geo_zip sz
           ON ST_WITHIN(
                TO_GEOGRAPHY(
                    'POINT(' || t."start_station_longitude" || ' ' || t."start_station_latitude" || ')'
                ),
                sz.zip_geom )
    /* end ZIP */
    LEFT JOIN geo_zip ez
           ON ST_WITHIN(
                TO_GEOGRAPHY(
                    'POINT(' || t."end_station_longitude" || ' ' || t."end_station_latitude" || ')'
                ),
                ez.zip_geom )
),

/* Add neighbourhood names ----------------------------------------*/
trip_neigh AS (
    SELECT  tz.*,
            sn.neighborhood AS start_neighborhood,
            en.neighborhood AS end_neighborhood
    FROM    trip_zips tz
    LEFT  JOIN neigh_lu sn ON sn.zip_code = tz.start_zip
    LEFT  JOIN neigh_lu en ON en.zip_code = tz.end_zip
    WHERE   sn.neighborhood IS NOT NULL
      AND   en.neighborhood IS NOT NULL
),

/* Central-Park weather (WBAN 94728) ------------------------------*/
wx AS (
    SELECT  TO_DATE( CONCAT_WS('-', "year", LPAD("mo",2,'0'), LPAD("da",2,'0')) ) AS trip_date,
            "temp",
            TRY_CAST("wdsp" AS FLOAT)  AS wdsp_knots,
            CASE WHEN "prcp" = 99.99 THEN NULL ELSE "prcp" END AS prcp_inches
    FROM    "NEW_YORK_CITIBIKE_1"."NOAA_GSOD"."GSOD2014"
    WHERE   "wban" = '94728'
),

/* Combine trips with weather -------------------------------------*/
trip_with_wx AS (
    SELECT  n.*,
            w."temp",
            w.wdsp_knots,
            w.prcp_inches
    FROM    trip_neigh n
    LEFT JOIN wx w ON w.trip_date = n.trip_date
),

/* Aggregate metrics ----------------------------------------------*/
agg AS (
    SELECT
        start_neighborhood,
        end_neighborhood,
        COUNT(*)                          AS total_trips,
        ROUND( AVG("tripduration")/60 ,1) AS avg_duration_min,
        ROUND( AVG("temp")           ,1)  AS avg_temp_f,
        ROUND( AVG(wdsp_knots*0.514444),1)AS avg_wind_mps,   -- knots→m/s
        ROUND( AVG(prcp_inches*2.54) ,1)  AS avg_prcp_cm     -- in→cm
    FROM   trip_with_wx
    GROUP  BY start_neighborhood, end_neighborhood
),

/* Month with most trips per pair ---------------------------------*/
peak_month AS (
    SELECT  start_neighborhood,
            end_neighborhood,
            trip_month AS peak_month
    FROM (
        SELECT  start_neighborhood,
                end_neighborhood,
                trip_month,
                ROW_NUMBER() OVER (
                    PARTITION BY start_neighborhood, end_neighborhood
                    ORDER BY COUNT(*) DESC) AS rn
        FROM    trip_neigh
        GROUP   BY start_neighborhood, end_neighborhood, trip_month
    )
    WHERE rn = 1
)

/* Final output ----------------------------------------------------*/
SELECT  a.start_neighborhood,
        a.end_neighborhood,
        a.total_trips,
        a.avg_duration_min,
        a.avg_temp_f,
        a.avg_wind_mps,
        a.avg_prcp_cm,
        p.peak_month
FROM    agg a
LEFT JOIN peak_month p
       ON p.start_neighborhood = a.start_neighborhood
      AND p.end_neighborhood   = a.end_neighborhood
ORDER  BY a.total_trips DESC NULLS LAST;