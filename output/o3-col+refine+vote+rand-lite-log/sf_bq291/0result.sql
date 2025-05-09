WITH target AS (   -- point of interest (lon 51.5 , lat 26.75)
    SELECT TO_GEOGRAPHY('POINT(51.5 26.75)') AS g
),

raw AS (           -- take the nearest grid-point for every forecast run, hours 24-48
    SELECT
        TO_DATE(TO_TIMESTAMP_NTZ(t."creation_time" / 1e6))            AS issue_date ,
        TO_DATE(TO_TIMESTAMP_NTZ(t."creation_time" / 1e6)) + 1        AS target_date ,
        f.value:"hours"::NUMBER                                       AS hours_ahead ,
        f.value:"temperature_2m_above_ground"::FLOAT                  AS temp_K ,
        f.value:"total_precipitation_surface"::FLOAT                  AS precip_mm ,
        f.value:"total_cloud_cover_entire_atmosphere"::FLOAT          AS cloud_pct ,
        ROW_NUMBER() OVER (PARTITION BY t."creation_time"
                           ORDER BY ST_DISTANCE(TO_GEOGRAPHY(t."geography"), tgt.g)) AS rn
    FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25  t
    CROSS JOIN target AS tgt
    ,     LATERAL FLATTEN(input => t."forecast")  f
    WHERE t."creation_time" BETWEEN 1561939200000000                    -- 2019-07-01 00:00 UTC
                               AND 1564617599000000                    -- 2019-07-31 23:59:59 UTC
      AND f.value:"hours"::NUMBER BETWEEN 24 AND 48                     -- next-day lead times
      QUALIFY rn = 1                                                    -- keep nearest grid-point
),

daily AS (        -- aggregate per forecast target-date
    SELECT
        target_date,
        MAX( temp_K * 9/5 - 459.67 )                                AS max_temp_F,
        MIN( temp_K * 9/5 - 459.67 )                                AS min_temp_F,
        AVG( temp_K * 9/5 - 459.67 )                                AS avg_temp_F,
        SUM( precip_mm )                                            AS total_precip_mm,
        AVG( CASE WHEN hours_ahead BETWEEN 34 AND 41
                  THEN cloud_pct END )                              AS avg_cloud_pct_10to17
    FROM raw
    GROUP BY target_date
)

SELECT
    target_date,
    max_temp_F,
    min_temp_F,
    avg_temp_F,
    total_precip_mm,
    avg_cloud_pct_10to17,
    CASE WHEN avg_temp_F < 32  THEN total_precip_mm ELSE 0 END  AS snow_mm,
    CASE WHEN avg_temp_F >= 32 THEN total_precip_mm ELSE 0 END  AS rain_mm
FROM daily
ORDER BY target_date;