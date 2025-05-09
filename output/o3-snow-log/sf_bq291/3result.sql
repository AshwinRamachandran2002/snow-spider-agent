/* Daily weather summary for July-2019 – nearest model grid-point
   to 26.75 N 51.50 E (next-day forecasts, hrs 24-47)                 */

WITH base AS (   -- all July-2019 forecasts, compute distance to target
    SELECT  *,
            ST_DISTANCE(
                TO_GEOGRAPHY("geography"),
                TO_GEOGRAPHY('POINT(51.5 26.75)')
            ) AS dist_m
    FROM "NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GFS0P25"
    WHERE "creation_time" BETWEEN 1561939200000000   -- 2019-07-01
                              AND     1564617599000000 -- 2019-07-31
          AND "geography" IS NOT NULL
),
nearest_point AS (   -- keep the single closest grid-point each run
    SELECT *
    FROM   base
    QUALIFY ROW_NUMBER() OVER (PARTITION BY "creation_time"
                               ORDER BY dist_m) = 1
),
next_day AS (        -- explode forecast array, keep hours 24-47
    SELECT
        DATE_TRUNC(
            'day',
            TO_TIMESTAMP_NTZ(f.value:"time"::NUMBER / 1e6)
        )                                   AS forecast_date,
        f.value:"hours"::INT                AS hours_ahead,
        f.value:"temperature_2m_above_ground"::FLOAT AS temp_k,
        f.value:"total_precipitation_surface"::FLOAT AS precip_mm,
        f.value:"total_cloud_cover_entire_atmosphere"::FLOAT AS cloud_pct
    FROM   nearest_point p,
           LATERAL FLATTEN(input => p."forecast") f
    WHERE  f.value:"hours"::INT BETWEEN 24 AND 47
),
daily AS (          -- aggregate required metrics
    SELECT
        forecast_date,
        MIN(temp_k)                                   AS min_temp_k,
        MAX(temp_k)                                   AS max_temp_k,
        AVG(temp_k)                                   AS avg_temp_k,
        SUM(precip_mm)                                AS total_precip_mm,
        AVG(CASE WHEN hours_ahead BETWEEN 34 AND 41
                 THEN cloud_pct END)                  AS avg_cloud_pct_10_17
    FROM   next_day
    GROUP  BY forecast_date
)
SELECT
    forecast_date,
    min_temp_k,
    max_temp_k,
    avg_temp_k,
    total_precip_mm,
    avg_cloud_pct_10_17,
    CASE WHEN avg_temp_k < 273.15 THEN total_precip_mm ELSE 0 END AS snowfall_mm,
    CASE WHEN avg_temp_k >= 273.15 THEN total_precip_mm ELSE 0 END AS rainfall_mm
FROM daily
ORDER BY forecast_date;