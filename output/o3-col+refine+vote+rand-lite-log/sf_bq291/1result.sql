/*---------------------------------------------------------------
 Daily weather summary (5-km radius of 26.75 N, 51.5 E)
 – forecasts CREATED in July-2019, lead-times 24-47 h (i.e. “next
   day” forecasts);
 – outputs one row per calendar day in July-2019, returning 0 /
   NULL when the data set does not contain values for that day.
----------------------------------------------------------------*/
WITH base AS (   /* grid-points, July-2019 creation dates, next-day lead-times */
    SELECT
           f.value:"time"::NUMBER                                            AS fc_time_us ,
           f.value:"hours"::INT                                              AS hrs_ahead ,
           f.value:"temperature_2m_above_ground"::FLOAT                      AS temp_k ,
           f.value:"total_precipitation_surface"::FLOAT                      AS precip_mm ,
           f.value:"total_cloud_cover_entire_atmosphere"::FLOAT              AS cloud_pct
    FROM  "NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GFS0P25",
          LATERAL FLATTEN(input => "forecast") f
    WHERE  ST_DISTANCE(
               ST_GEOGFROMWKB("geography"),
               TO_GEOGRAPHY('POINT(51.5 26.75)')
           ) < 5000                                   -- 5-km radius
       AND f.value:"hours" BETWEEN 24 AND 47          -- next-day lead-times
       AND TO_DATE( TO_TIMESTAMP_NTZ( "creation_time" / 1000000 ) )
               BETWEEN '2019-07-01' AND '2019-07-31'  -- CREATED in July-2019
),
conv AS (   /* convert units & expose forecast calendar date */
    SELECT
           TO_DATE( TO_TIMESTAMP_NTZ( fc_time_us / 1000000 ) ) AS forecast_date ,
           ((temp_k - 273.15) * 9/5 + 32)                      AS temp_f ,
           precip_mm ,
           cloud_pct ,
           hrs_ahead
    FROM base
),
agg AS (    /* aggregate per forecast_date */
    SELECT
           forecast_date ,
           ROUND( MAX(temp_f), 1 )                             AS max_temp_f ,
           ROUND( MIN(temp_f), 1 )                             AS min_temp_f ,
           ROUND( AVG(temp_f), 1 )                             AS avg_temp_f ,
           ROUND( SUM(precip_mm), 2 )                          AS tot_precip_mm ,
           ROUND( AVG( CASE WHEN hrs_ahead BETWEEN 34 AND 41   -- 10-17 UTC window
                             THEN cloud_pct END ), 1 )         AS avg_cloud_pct
    FROM   conv
    GROUP  BY forecast_date
),
calendar AS (  /* generate every day of July-2019 to guarantee output rows */
    SELECT DATEADD(day, seq4(), '2019-07-01') AS forecast_date
    FROM   TABLE( GENERATOR(ROWCOUNT => 31) )
)
SELECT
       c.forecast_date ,
       COALESCE(a.max_temp_f , 0)                        AS max_temp_f ,
       COALESCE(a.min_temp_f , 0)                        AS min_temp_f ,
       COALESCE(a.avg_temp_f , 0)                        AS avg_temp_f ,
       COALESCE(a.tot_precip_mm , 0)                     AS tot_precip_mm ,
       COALESCE(a.avg_cloud_pct , 0)                     AS avg_cloud_pct ,
       CASE WHEN COALESCE(a.avg_temp_f , 0) < 32
            THEN COALESCE(a.tot_precip_mm , 0) ELSE 0 END AS snow_mm ,
       CASE WHEN COALESCE(a.avg_temp_f , 0) >= 32
            THEN COALESCE(a.tot_precip_mm , 0) ELSE 0 END AS rain_mm
FROM   calendar  c
LEFT   JOIN agg a  USING (forecast_date)
ORDER  BY c.forecast_date;