/* ---------------------------------------------------------------------------
   Daily weather summary for July-2019
   – next-day GFS forecasts (lead-time 24-47 h)
   – within 5-km radius of POINT(51.5 26.75)
   – returns one row per calendar-day (31 rows)
--------------------------------------------------------------------------- */

WITH base AS (  -- individual forecast points that meet all filters
    SELECT
        /* creation_time (µs) + lead-time (hrs) → TIMESTAMP_NTZ */
        TO_TIMESTAMP_NTZ(
            (t."creation_time" + f.value:"hours"::NUMBER * 3600000000) / 1000000
        )                                             AS forecast_ts,
        f.value:"temperature_2m_above_ground"::FLOAT          AS temp_c,
        f.value:"total_precipitation_surface"::FLOAT          AS precip_mm,
        f.value:"total_cloud_cover_entire_atmosphere"::FLOAT  AS cloud_pct
    FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25 t,
         LATERAL FLATTEN(input => t."forecast") f
    WHERE
          t."creation_time" BETWEEN 1561939200000000       -- 2019-07-01 00:00 UTC
                               AND 1564617600000000       -- 2019-07-31 23:59 UTC
      AND f.value:"hours"::NUMBER BETWEEN 24 AND 47        -- next-day forecasts
      AND ST_DISTANCE(                                     -- 5-km radius filter
              TRY_TO_GEOGRAPHY(t."geography"),
              TO_GEOGRAPHY('POINT(51.5 26.75)')
          ) <= 5000
),
daily AS (      -- aggregate to one row per forecast date (if data exist)
    SELECT
        DATE_TRUNC('day', forecast_ts)                        AS forecast_date,
        MAX(temp_c)                                           AS max_temp_c,
        MIN(temp_c)                                           AS min_temp_c,
        AVG(temp_c)                                           AS avg_temp_c,
        SUM(COALESCE(precip_mm,0))                            AS total_precip_mm,
        AVG(
            CASE
                WHEN EXTRACT(hour FROM forecast_ts) BETWEEN 10 AND 17
                THEN cloud_pct
            END
        )                                                     AS avg_cloud_pct_daylight
    FROM base
    GROUP BY 1
)
-- generate all calendar days in July-2019 and left-join aggregates
SELECT
    cal.forecast_date,
    d.max_temp_c,
    d.min_temp_c,
    d.avg_temp_c,
    d.total_precip_mm,
    d.avg_cloud_pct_daylight,
    /* classify precipitation by daily average temperature (0 °C ≈ 32 °F) */
    CASE WHEN d.avg_temp_c < 0  THEN d.total_precip_mm ELSE 0 END AS total_snow_mm,
    CASE WHEN d.avg_temp_c >= 0 THEN d.total_precip_mm ELSE 0 END AS total_rain_mm
FROM (
        /* sequence 0-30 → dates 2019-07-01 .. 2019-07-31 */
        SELECT DATEADD(day, SEQ4(), '2019-07-01') AS forecast_date
        FROM TABLE(GENERATOR(ROWCOUNT => 31))
     ) cal
LEFT JOIN daily d
       ON cal.forecast_date = d.forecast_date
ORDER BY cal.forecast_date;