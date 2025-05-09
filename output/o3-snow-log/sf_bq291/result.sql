WITH target AS (                               -- correct WKT = POINT(longitude latitude)
    SELECT TO_GEOGRAPHY('POINT(26.75 51.5)') AS g
),
flat AS (                                     -- July-2019 forecasts, 30-km radius, lead-hours 24-47 (next-day)
    SELECT
        CAST(
            DATEADD(
                SECOND,
                (t."creation_time" / 1000000) + f.value:"hours"::INT * 3600,
                TO_TIMESTAMP_NTZ('1970-01-01')
            ) AS DATE
        )                                                        AS "forecast_date",
        f.value:"hours"::INT                                     AS "lead_hour",
        f.value:"temperature_2m_above_ground"::FLOAT             AS "temp_k",
        f.value:"total_precipitation_surface"::FLOAT             AS "precip_mm",
        f.value:"total_cloud_cover_entire_atmosphere"::FLOAT     AS "cloud_pct"
    FROM "NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GFS0P25" t
         ,LATERAL FLATTEN(input => t."forecast") f
         ,target p
    WHERE t."creation_time" BETWEEN 1561939200000000 AND 1564617600000000  -- 2019-07-01 to 2019-07-31
      AND ST_DISTANCE( TO_GEOGRAPHY(t."geography"), p.g ) <= 30000         -- 30-km radius
      AND f.value:"hours"::INT BETWEEN 24 AND 47                           -- next-day window
),
daily AS (                                           -- aggregate by forecast_date
    SELECT
        "forecast_date",
        MAX("temp_k")                                    AS "max_temp_k",
        MIN("temp_k")                                    AS "min_temp_k",
        AVG("temp_k")                                    AS "avg_temp_k",
        SUM("precip_mm")                                 AS "total_precip_mm",
        AVG(CASE WHEN "lead_hour" BETWEEN 24 AND 31
                 THEN "cloud_pct" END)                   AS "avg_cloud_pct_10to17"
    FROM flat
    GROUP BY "forecast_date"
)
SELECT
    "forecast_date",
    "max_temp_k",
    "min_temp_k",
    "avg_temp_k",
    "total_precip_mm",
    "avg_cloud_pct_10to17",
    CASE WHEN "avg_temp_k" < 273.15
         THEN "total_precip_mm" ELSE 0 END              AS "total_snowfall_mm",
    CASE WHEN "avg_temp_k" >= 273.15
         THEN "total_precip_mm" ELSE 0 END              AS "total_rainfall_mm"
FROM daily
ORDER BY "forecast_date";