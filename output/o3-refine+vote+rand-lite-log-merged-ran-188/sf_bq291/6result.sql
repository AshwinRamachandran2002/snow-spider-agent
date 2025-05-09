/*  Daily “next-day” weather summary for forecasts CREATED in July-2019.
    • Uses the grid-point closest to (51.5 E , 26.75 N) for each forecast run.
    • Summarises hours-ahead 24-47 (i.e. the following day).                */
WITH nearest_pts AS (        -- one grid-point (nearest) per creation time
    SELECT
        "creation_time",
        "forecast"
    FROM (
        SELECT
            "creation_time",
            "forecast",
            ROW_NUMBER() OVER (
                PARTITION BY "creation_time"
                ORDER BY ST_DISTANCE(
                           TO_GEOGRAPHY("geography"),
                           TO_GEOGRAPHY('POINT(51.5 26.75)')
                         )
            ) AS rn
        FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM."NOAA_GFS0P25"
        WHERE "creation_time" BETWEEN 1561939200000000   -- 2019-07-01 00:00 UTC
                                 AND     1564617600000000   -- 2019-08-01 00:00 UTC
    )
    WHERE rn = 1
), hrs24_47 AS (             -- expand forecast-array; keep hours 24-47
    SELECT
        TO_DATE( TO_TIMESTAMP_NTZ(f.value:"time"::NUMBER / 1e6) )             AS forecast_date,
        EXTRACT(hour FROM TO_TIMESTAMP_NTZ(f.value:"time"::NUMBER / 1e6))     AS utc_hour,
        f.value:"temperature_2m_above_ground"::FLOAT                          AS temp_C,
        f.value:"total_precipitation_surface"::FLOAT                          AS precip_mm,
        f.value:"total_cloud_cover_entire_atmosphere"::FLOAT                  AS cloud_pct
    FROM nearest_pts,
         LATERAL FLATTEN( INPUT => "forecast" ) f
    WHERE f.value:"hours"::INT BETWEEN 24 AND 47
), day_aggr AS (             -- daily aggregates
    SELECT
        forecast_date,
        MIN(temp_C)                                                             AS min_temp_C,
        MAX(temp_C)                                                             AS max_temp_C,
        AVG(temp_C)                                                             AS avg_temp_C,
        SUM(precip_mm)                                                          AS total_precip_mm,
        AVG(CASE WHEN utc_hour BETWEEN 10 AND 17 THEN cloud_pct END)            AS avg_cloud_pct_10_17
    FROM hrs24_47
    GROUP BY forecast_date
)
SELECT
    forecast_date,
    min_temp_C,
    max_temp_C,
    avg_temp_C,
    total_precip_mm,
    avg_cloud_pct_10_17,
    CASE WHEN avg_temp_C < 0 THEN total_precip_mm ELSE 0 END  AS total_snow_mm,
    CASE WHEN avg_temp_C >= 0 THEN total_precip_mm ELSE 0 END AS total_rain_mm
FROM day_aggr
ORDER BY forecast_date;