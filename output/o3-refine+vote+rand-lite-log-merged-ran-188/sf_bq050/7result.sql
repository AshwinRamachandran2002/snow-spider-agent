/*  NYC Citi Bike 2014 OD flows with Central-Park daily weather           */
WITH trips_2014 AS (  -----------------------------------------------------
    SELECT  t.* ,
            TO_TIMESTAMP(t."starttime"/1e6)                    AS start_ts ,
            CAST(TO_TIMESTAMP(t."starttime"/1e6) AS DATE)      AS trip_date ,
            EXTRACT(month FROM TO_TIMESTAMP(t."starttime"/1e6)) AS trip_month ,
            t."tripduration"/60.0                              AS trip_minutes
    FROM   NEW_YORK_CITIBIKE_1.NEW_YORK_CITIBIKE.CITIBIKE_TRIPS t
    WHERE  YEAR(TO_TIMESTAMP(t."starttime"/1e6)) = 2014
),
------------------------------------------------------------------------
geo_zip AS (          /* NY-state ZIP polygons                            */
    SELECT  z."zip_code" ,
            TO_GEOGRAPHY(z."zip_code_geom") AS zip_geom
    FROM    NEW_YORK_CITIBIKE_1.GEO_US_BOUNDARIES.ZIP_CODES z
    WHERE   z."state_code" = 'NY'
),
------------------------------------------------------------------------
trips_zipped AS (     /* spatial join → ZIP codes                         */
    SELECT
        t.* ,
        sz."zip_code"::NUMBER AS start_zip ,
        ez."zip_code"::NUMBER AS end_zip
    FROM   trips_2014 t
    JOIN   geo_zip sz
      ON ST_WITHIN(
           TO_GEOGRAPHY('POINT('||t."start_station_longitude"||' '||t."start_station_latitude"||')'),
           sz.zip_geom)
    JOIN   geo_zip ez
      ON ST_WITHIN(
           TO_GEOGRAPHY('POINT('||t."end_station_longitude"||' '||t."end_station_latitude"||')'),
           ez.zip_geom)
),
------------------------------------------------------------------------
trips_neigh AS (      /* map ZIP → borough / neighbourhood                */
    SELECT
        tz.* ,
        z1."borough"      AS start_borough ,
        z1."neighborhood" AS start_neighborhood ,
        z2."borough"      AS end_borough ,
        z2."neighborhood" AS end_neighborhood
    FROM   trips_zipped tz
    JOIN   NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES z1
           ON z1."zip" = tz.start_zip
    JOIN   NEW_YORK_CITIBIKE_1.CYCLISTIC.ZIP_CODES z2
           ON z2."zip" = tz.end_zip
),
------------------------------------------------------------------------
weather AS (          /* Central Park daily means, units converted        */
    SELECT
        TO_DATE("year"||'-'||LPAD("mo",2,'0')||'-'||LPAD("da",2,'0')) AS wx_date ,
        CAST("temp" AS FLOAT)                           AS temp_f ,
        CAST("wdsp" AS FLOAT) * 0.514444                AS wind_mps ,   -- knots → m/s
        CAST("prcp" AS FLOAT) * 2.54                    AS prcp_cm      -- inches → cm
    FROM   NEW_YORK_CITIBIKE_1.NOAA_GSOD.GSOD2014
    WHERE  "stn" = '725033'  AND "wban" = '94728'                      -- Central Park
),
------------------------------------------------------------------------
trips_wx AS (         /* attach weather of trip date                      */
    SELECT  n.* ,
            w.temp_f ,
            w.wind_mps ,
            w.prcp_cm
    FROM   trips_neigh n
    LEFT  JOIN weather w
           ON w.wx_date = n.trip_date
),
------------------------------------------------------------------------
month_counts AS (     /* trip count per OD pair and month                 */
    SELECT  start_neighborhood ,
            end_neighborhood ,
            trip_month ,
            COUNT(*) AS trips_in_month
    FROM    trips_wx
    GROUP  BY 1,2,3
),
busiest AS (          /* month with most trips for each OD pair           */
    SELECT  start_neighborhood ,
            end_neighborhood ,
            trip_month AS busiest_month
    FROM (
        SELECT m.* ,
               ROW_NUMBER() OVER (PARTITION BY start_neighborhood, end_neighborhood
                                   ORDER BY trips_in_month DESC, trip_month) AS rn
        FROM   month_counts m
    )
    WHERE  rn = 1
),
------------------------------------------------------------------------
summary AS (          /* final metrics                                     */
    SELECT
        start_neighborhood ,
        end_neighborhood ,
        COUNT(*)                            AS total_trips ,
        ROUND(AVG(trip_minutes) ,1)         AS avg_trip_minutes ,
        ROUND(AVG(temp_f)      ,1)          AS avg_temperature_f ,
        ROUND(AVG(wind_mps)    ,1)          AS avg_wind_mps ,
        ROUND(AVG(prcp_cm)     ,1)          AS avg_prcp_cm
    FROM   trips_wx
    GROUP  BY 1,2
)
------------------------------------------------------------------------
SELECT
    s.start_neighborhood ,
    s.end_neighborhood ,
    s.total_trips ,
    s.avg_trip_minutes ,
    s.avg_temperature_f ,
    s.avg_wind_mps ,
    s.avg_prcp_cm ,
    b.busiest_month
FROM   summary s
LEFT  JOIN busiest b
       ON b.start_neighborhood = s.start_neighborhood
      AND b.end_neighborhood   = s.end_neighborhood
ORDER BY s.total_trips DESC NULLS LAST;