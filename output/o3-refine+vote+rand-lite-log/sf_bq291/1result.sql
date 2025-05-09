/*  Daily weather summary for July‑2019
    – 5‑km neighbourhood of 26.75 N, 51.50 E
    – each record summarises NEXT‑DAY weather predicted by a forecast
      that was CREATED in July‑2019                                       */

WITH ref_point AS (                     -- reference location
    SELECT TO_GEOGRAPHY('POINT(51.5 26.75)') AS "p"
),

base AS (                               -- explode the forecast arrays
    SELECT
        /* creation date of the forecast (UTC) */
        TO_DATE(TO_TIMESTAMP_NTZ(g."creation_time" / 1e6))                 AS "creation_date",

        /* date the forecast refers to (UTC) */
        TO_DATE(TO_TIMESTAMP_NTZ(f.value:"time"::NUMBER / 1e6))            AS "forecast_date",

        /* weather variables (already in SI units) */
        f.value:"temperature_2m_above_ground"::FLOAT                       AS "temp_c",
        f.value:"total_precipitation_surface"::FLOAT                       AS "precip_mm",
        f.value:"total_cloud_cover_entire_atmosphere"::FLOAT               AS "cloud_pct",

        EXTRACT(
            HOUR FROM TO_TIMESTAMP_NTZ(f.value:"time"::NUMBER / 1e6)
        )                                                                  AS "hour_utc"
    FROM "NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GLOBAL_FORECAST_SYSTEM"."NOAA_GFS0P25" g
    JOIN ref_point r
          /* use grid‑cell centre point and keep only those ≤5 km away   */
          ON ST_DISTANCE( TO_GEOGRAPHY(g."geography") , r."p") <= 5000
    ,   LATERAL FLATTEN(input => g."forecast")  f
    WHERE
          /* forecasts CREATED during July‑2019                          */
          TO_DATE(TO_TIMESTAMP_NTZ(g."creation_time" / 1e6))
              BETWEEN '2019-07-01' AND '2019-07-31'
      AND /* use only NEXT‑DAY forecasts (target‑date = creation + 1)    */
          TO_DATE(TO_TIMESTAMP_NTZ(f.value:"time"::NUMBER / 1e6))
              = TO_DATE(TO_TIMESTAMP_NTZ(g."creation_time" / 1e6)) + 1
),

daily AS (                               -- aggregate to one row per forecast date
    SELECT
        "forecast_date",
        MAX("temp_c")                                                         AS "max_temp_c",
        MIN("temp_c")                                                         AS "min_temp_c",
        AVG("temp_c")                                                         AS "avg_temp_c",
        SUM("precip_mm")                                                      AS "total_precip_mm",
        /* average cloud cover between 10:00–16:59 UTC (≈10 AM–5 PM local) */
        AVG(IFF("hour_utc" BETWEEN 10 AND 16, "cloud_pct", NULL))             AS "avg_cloud_10_17_pct"
    FROM base
    GROUP BY "forecast_date"
),

all_days AS (                            -- ensure one row for every day in July
    SELECT DATEADD(day, SEQ4(), '2019-07-01') AS "forecast_date"
    FROM TABLE(GENERATOR(ROWCOUNT => 31))
)

SELECT
    d."forecast_date",
    /* statistics (NULL when no data available for that day) */
    "max_temp_c",
    "min_temp_c",
    "avg_temp_c",
    "total_precip_mm",
    "avg_cloud_10_17_pct",

    /* snowfall vs rainfall split based on average daily temperature (°F) */
    IFF(("avg_temp_c"*9/5+32) < 32,  "total_precip_mm", 0)  AS "total_snowfall_mm",
    IFF(("avg_temp_c"*9/5+32) >= 32, "total_precip_mm", 0)  AS "total_rainfall_mm"

FROM          all_days        d
LEFT JOIN     daily           s  USING ("forecast_date")
ORDER BY      d."forecast_date";