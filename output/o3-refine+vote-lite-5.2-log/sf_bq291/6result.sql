/*  Daily weather summary for July‑2019
    Location : 26.75 N , 51.50 E  (choose the nearest model grid‑point for every run)
    “Creation time”  : forecast initialisation time (only runs started in July‑2019)
    “Target date”    : creation‑date + 1 day  (i.e. the day being forecast)
*/
WITH nearest_points AS (      -- choose the closest grid‑point for every model run
    SELECT  *,
            TO_TIMESTAMP_NTZ("creation_time" / 1e6)                           AS creation_ts,
            ST_DISTANCE(
                TO_GEOGRAPHY("geography"),
                TO_GEOGRAPHY('POINT(51.5 26.75)')
            )                                                                 AS dist_m,
            ROW_NUMBER() OVER (PARTITION BY "creation_time"
                               ORDER BY ST_DISTANCE(
                                            TO_GEOGRAPHY("geography"),
                                            TO_GEOGRAPHY('POINT(51.5 26.75)')
                                        ))                                    AS rn
    FROM    NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25
    WHERE   TO_TIMESTAMP_NTZ("creation_time" / 1e6) >= '2019-07-01'::DATE
      AND   TO_TIMESTAMP_NTZ("creation_time" / 1e6) <  '2019-08-01'::DATE
),
points AS (
    SELECT * 
    FROM   nearest_points 
    WHERE  rn = 1                       -- keep only the nearest grid‑point per run
),
forecasts AS (      -- explode hourly forecast arrays
    SELECT  p.creation_ts,
            DATEADD(day, 1, DATE_TRUNC(day, p.creation_ts))                   AS target_date,
            TO_TIMESTAMP_NTZ(f.value:"time"::NUMBER / 1e6)                    AS forecast_ts,
            f.value:"temperature_2m_above_ground"::FLOAT                      AS temp_c,
            f.value:"total_precipitation_surface"::FLOAT                      AS precip_mm,
            f.value:"total_cloud_cover_entire_atmosphere"::FLOAT              AS cloud_pct
    FROM    points p,
            LATERAL FLATTEN(input => p."forecast") f
),
day_data AS (       -- keep records that belong to the NEXT‑DAY being forecast
    SELECT *
    FROM   forecasts
    WHERE  DATE_TRUNC('day', forecast_ts) = target_date
),
daily_agg AS (      -- aggregate metrics per forecast date
    SELECT  target_date                                                       AS forecast_date,
            ROUND(MAX(temp_c), 4)                                             AS max_temperature_c,
            ROUND(MIN(temp_c), 4)                                             AS min_temperature_c,
            ROUND(AVG(temp_c), 4)                                             AS avg_temperature_c,
            ROUND(SUM(precip_mm), 4)                                          AS total_precipitation_mm,
            ROUND(AVG(
                    CASE 
                        WHEN EXTRACT(hour FROM forecast_ts) BETWEEN 10 AND 17 
                        THEN cloud_pct 
                    END
                 ), 4)                                                        AS avg_cloud_cover_10_17_pct
    FROM    day_data
    GROUP BY target_date
)
SELECT  forecast_date,
        max_temperature_c,
        min_temperature_c,
        avg_temperature_c,
        total_precipitation_mm,
        avg_cloud_cover_10_17_pct,
        CASE WHEN avg_temperature_c < 0 
             THEN total_precipitation_mm ELSE 0 END                           AS total_snowfall_mm,
        CASE WHEN avg_temperature_c >= 0 
             THEN total_precipitation_mm ELSE 0 END                           AS total_rainfall_mm
FROM    daily_agg
ORDER BY forecast_date;