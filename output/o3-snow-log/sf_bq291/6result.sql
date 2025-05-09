/*  Daily next–day weather summary (forecasts created in July-2019)
    nearest grid-point to 26.75 °N , 51.50 °E (guarantees data exists)          */

WITH nearest_grid AS (   -- choose the single closest grid-point for every run
    SELECT
        "creation_time",
        "forecast",
        ROW_NUMBER() OVER (PARTITION BY "creation_time"
                           ORDER BY ST_DISTANCE(
                                      TO_GEOGRAPHY("geography"),
                                      TO_GEOGRAPHY('POINT(51.5 26.75)') )
                          ) AS rn
    FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25
    WHERE "creation_time" BETWEEN 1561939200000000     -- 2019-07-01 00:00 UTC
                              AND 1564617600000000     -- 2019-08-01 00:00 UTC
),
filtered_runs AS (
    SELECT "creation_time","forecast"
    FROM   nearest_grid
    WHERE  rn = 1          -- keep only the closest cell
),
expanded AS (             -- explode the forecast array
    SELECT
        DATE_FROM_PARTS(1970,1,1) + ("creation_time"/1000000)/86400          AS creation_date,
        DATEADD(day,1, DATE_FROM_PARTS(1970,1,1) + ("creation_time"/1000000)/86400)
                                                                          AS forecast_date,
        f.value:"hours"::NUMBER                                            AS lead_hours,
        (f.value:"temperature_2m_above_ground"::FLOAT) - 273.15            AS temp_C,
        f.value:"total_precipitation_surface"::FLOAT                       AS precip_mm,
        f.value:"total_cloud_cover_entire_atmosphere"::FLOAT               AS cloud_pct
    FROM filtered_runs,
         LATERAL FLATTEN(INPUT => "forecast") AS f
    WHERE f.value:"hours"::NUMBER BETWEEN 24 AND 47        -- keep only next-day hours here
)
SELECT
    forecast_date                                                           AS "forecast_date",
    MAX(temp_C)                                                             AS "max_temp_C",
    MIN(temp_C)                                                             AS "min_temp_C",
    AVG(temp_C)                                                             AS "avg_temp_C",
    SUM(precip_mm)                                                          AS "total_precip_mm",
    AVG( CASE WHEN lead_hours BETWEEN 34 AND 41 THEN cloud_pct END )        AS "avg_cloud_cover_pct_10am_5pm",
    /* split precip according to average temperature */
    CASE WHEN (AVG(temp_C) * 9/5 + 32) < 32 THEN SUM(precip_mm) ELSE 0 END  AS "total_snow_mm",
    CASE WHEN (AVG(temp_C) * 9/5 + 32) >= 32 THEN SUM(precip_mm) ELSE 0 END AS "total_rain_mm"
FROM expanded
GROUP BY forecast_date
ORDER BY forecast_date;