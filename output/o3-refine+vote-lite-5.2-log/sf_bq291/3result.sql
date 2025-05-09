/*  Daily weather summary – July 2019
    Target location : 26.75 °N , 51.50 °E
    Data source     : NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25   */
WITH base AS (   -- all forecast cycles CREATED during July‑2019 + GEOGRAPHY cast
    SELECT
        TO_TIMESTAMP("creation_time" / 1000000)                     AS creation_ts,
        "forecast",
        TO_GEOGRAPHY("geography")                                   AS geo
    FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25
    WHERE DATE(TO_TIMESTAMP("creation_time" / 1000000))
          BETWEEN '2019-07-01' AND '2019-07-31'
          AND "geography" IS NOT NULL
),                               -- rank grid‑points by distance to target point
dist_rank AS (
    SELECT
        creation_ts,
        "forecast",
        ST_DISTANCE(
            geo,
            TO_GEOGRAPHY('POINT (51.5 26.75)')
        )                                        AS dist_m,
        ROW_NUMBER() OVER (PARTITION BY creation_ts
                           ORDER BY ST_DISTANCE(
                               geo,
                               TO_GEOGRAPHY('POINT (51.5 26.75)')
                           ))                    AS rn
    FROM base
),                               -- choose the nearest grid‑point for each run
nearest AS (
    SELECT creation_ts, "forecast"
    FROM dist_rank
    WHERE rn = 1
),                               -- explode hourly forecast array
flat AS (
    SELECT
        creation_ts,
        f.VALUE:"hours"::INT                                   AS hrs_ahead,
        TO_TIMESTAMP_NTZ(
            DATE_PART(EPOCH_SECOND, creation_ts)
            + f.VALUE:"hours"::INT * 3600
        )                                                      AS forecast_ts,
        f.VALUE:"temperature_2m_above_ground"::FLOAT           AS temp_c,
        COALESCE(f.VALUE:"total_precipitation_surface", 0)::FLOAT
                                                               AS precip_mm,
        f.VALUE:"total_cloud_cover_entire_atmosphere"::FLOAT   AS cloud_pct
    FROM nearest,
         LATERAL FLATTEN(INPUT => nearest."forecast") f
),                               -- keep only hours VALID the day after creation
next_day AS (
    SELECT
        DATE(forecast_ts)      AS forecast_date,
        temp_c,
        precip_mm,
        cloud_pct,
        forecast_ts
    FROM flat
    WHERE DATE(forecast_ts) = DATE(creation_ts) + 1
),                               -- daily aggregates
daily AS (
    SELECT
        forecast_date,
        MAX(temp_c)                                                AS max_temp_c,
        MIN(temp_c)                                                AS min_temp_c,
        AVG(temp_c)                                                AS avg_temp_c,
        SUM(precip_mm)                                             AS total_precip_mm,
        AVG(CASE WHEN HOUR(forecast_ts) BETWEEN 10 AND 16
                 THEN cloud_pct END)                               AS avg_cloud_cover_10_17
    FROM next_day
    GROUP BY forecast_date
)
SELECT
    forecast_date,
    max_temp_c,
    min_temp_c,
    avg_temp_c,
    total_precip_mm,
    avg_cloud_cover_10_17,
    CASE WHEN (avg_temp_c * 9/5 + 32) < 32
         THEN total_precip_mm ELSE 0 END  AS total_snowfall_mm,
    CASE WHEN (avg_temp_c * 9/5 + 32) >= 32
         THEN total_precip_mm ELSE 0 END  AS total_rainfall_mm
FROM daily
ORDER BY forecast_date;