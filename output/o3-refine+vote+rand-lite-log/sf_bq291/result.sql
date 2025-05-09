/*------------------------------------------------------------------
Daily weather summary for forecasts CREATED in July‑2019 whose model
grid‑point is the NEAREST (within the whole grid) to 26.75 N 51.5 E
and that refer to the FOLLOWING‑DAY weather.
------------------------------------------------------------------*/
WITH
/*------------------------------------------------------------------
Point of interest
------------------------------------------------------------------*/
params AS (
    SELECT TO_GEOGRAPHY('POINT(51.5 26.75)') AS "CENTER_GEOM"
),
/*------------------------------------------------------------------
For every model run (creation_time) pick the single grid‑point that
is closest to the requested coordinates, then unpack its forecast
array.
------------------------------------------------------------------*/
nearest_gridpoint AS (
    SELECT
        g."creation_time",
        g."forecast",
        /* choose the nearest grid‑point per creation_time           */
        ROW_NUMBER() OVER (
            PARTITION BY g."creation_time"
            ORDER BY ST_DISTANCE(TO_GEOGRAPHY(g."geography"),
                                  p."CENTER_GEOM")
        ) AS "RN"
    FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25 g,
         params p
    WHERE
          TO_TIMESTAMP_NTZ(g."creation_time" / 1e6) >= '2019-07-01'
      AND TO_TIMESTAMP_NTZ(g."creation_time" / 1e6) <  '2019-08-01'
),
/*------------------------------------------------------------------
Keep only the nearest gridpoint rows (RN = 1) and flatten forecasts
------------------------------------------------------------------*/
flat AS (
    SELECT
        TO_TIMESTAMP_NTZ(ng."creation_time" / 1e6)                      AS "CREATION_TS",
        DATE_TRUNC('day',
                   TO_TIMESTAMP_NTZ(ng."creation_time" / 1e6))          AS "CREATION_DATE",
        f.value                                                         AS "F"
    FROM nearest_gridpoint ng
         ,LATERAL FLATTEN(INPUT => ng."forecast") f
    WHERE ng."RN" = 1
),
/*------------------------------------------------------------------
Extract variables of interest from every forecast hour
------------------------------------------------------------------*/
forecast_data AS (
    SELECT
        "CREATION_DATE",
        TO_TIMESTAMP_NTZ("F":"time"::NUMBER / 1e6)                       AS "FORECAST_TS",
        "F":"temperature_2m_above_ground"::FLOAT                         AS "TEMP_C",
        COALESCE("F":"total_precipitation_surface"::FLOAT, 0)            AS "PRECIP_MM",
        "F":"total_cloud_cover_entire_atmosphere"::FLOAT                 AS "CLOUD_COVER_PCT"
    FROM flat
),
/*------------------------------------------------------------------
Keep hours that belong to the next calendar DAY after creation
------------------------------------------------------------------*/
next_day AS (
    SELECT
        DATE_TRUNC('day', "FORECAST_TS")                                 AS "FORECAST_DATE",
        "TEMP_C",
        "PRECIP_MM",
        "CLOUD_COVER_PCT",
        EXTRACT(hour FROM "FORECAST_TS")                                 AS "HOUR_OF_DAY"
    FROM forecast_data
    WHERE DATE_TRUNC('day', "FORECAST_TS") = DATEADD(day, 1, "CREATION_DATE")
),
/*------------------------------------------------------------------
Aggregate metrics per forecast date
------------------------------------------------------------------*/
daily AS (
    SELECT
        "FORECAST_DATE",
        MIN("TEMP_C")                                                    AS "MIN_TEMP_C",
        MAX("TEMP_C")                                                    AS "MAX_TEMP_C",
        AVG("TEMP_C")                                                    AS "AVG_TEMP_C",
        SUM("PRECIP_MM")                                                 AS "TOTAL_PRECIP_MM",
        AVG(CASE WHEN "HOUR_OF_DAY" BETWEEN 10 AND 17
                 THEN "CLOUD_COVER_PCT" END)                             AS "AVG_CLOUD_COVER_10_17"
    FROM next_day
    GROUP BY "FORECAST_DATE"
)
/*------------------------------------------------------------------
Final output with snowfall / rainfall split (32 °F ↔ 0 °C)
------------------------------------------------------------------*/
SELECT
    "FORECAST_DATE",
    "MIN_TEMP_C",
    "MAX_TEMP_C",
    "AVG_TEMP_C",
    "TOTAL_PRECIP_MM",
    "AVG_CLOUD_COVER_10_17",
    CASE WHEN "AVG_TEMP_C" <   0 THEN "TOTAL_PRECIP_MM" ELSE 0 END       AS "TOTAL_SNOWFALL_MM",
    CASE WHEN "AVG_TEMP_C" >= 0 THEN "TOTAL_PRECIP_MM" ELSE 0 END        AS "TOTAL_RAINFALL_MM"
FROM daily
ORDER BY "FORECAST_DATE";