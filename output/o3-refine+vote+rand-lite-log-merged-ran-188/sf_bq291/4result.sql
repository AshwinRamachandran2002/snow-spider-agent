/*---------------------------------------------------------------
  Daily weather summary (next-day forecasts) for July-2019
  using the grid-point nearest to 26.75 N, 51.50 E for every
  model-run (creation_time) stored in the GFS 0.25° table.
----------------------------------------------------------------*/
WITH
    /* reference location */
    params AS (
        SELECT TO_GEOGRAPHY('POINT(51.5 26.75)') AS "center"
    ),

    /* choose ONE grid-point (the nearest) for every model run
       created in July-2019 UTC                                       */
    nearest AS (
        SELECT
            t."creation_time",
            t."forecast"                                AS "forecast"
        FROM NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GLOBAL_FORECAST_SYSTEM.NOAA_GFS0P25 t,
             params p
        WHERE
              /* restrict to model runs produced in July-2019 */
              TO_DATE(TO_TIMESTAMP_NTZ(t."creation_time" / 1000000))
                  BETWEEN '2019-07-01' AND '2019-07-31'
        QUALIFY
            ROW_NUMBER() OVER (                       -- pick nearest grid-point
                PARTITION BY t."creation_time"
                ORDER BY ST_DISTANCE(
                            TO_GEOGRAPHY(t."geography"),
                            p."center"
                         )
            ) = 1
    ),

    /* explode hourly elements for those chosen grid-points */
    hourly AS (
        SELECT
            /* forecast applies to CALENDAR DAY after creation */
            DATE_TRUNC(
                'day',
                TO_TIMESTAMP_NTZ(n."creation_time" / 1000000) + INTERVAL '1 day'
            )                                          AS "forecast_date",

            f.value:"hours"::INT                       AS "h",

            /* temperature K → °F */
            ((f.value:"temperature_2m_above_ground"::FLOAT) - 273.15) * 9/5 + 32
                                                     AS "temp_f",

            /* precipitation (mm) */
            COALESCE(f.value:"total_precipitation_surface"::FLOAT, 0)
                                                     AS "precip_mm",

            /* cloud cover (%) */
            f.value:"total_cloud_cover_entire_atmosphere"::FLOAT
                                                     AS "cloud_pct"
        FROM nearest n,
             LATERAL FLATTEN(input => n."forecast") f
    ),

    /* aggregate to daily level */
    daily AS (
        SELECT
            "forecast_date",
            MAX("temp_f")                                              AS "max_temp_f",
            MIN("temp_f")                                              AS "min_temp_f",
            AVG("temp_f")                                              AS "avg_temp_f",
            SUM("precip_mm")                                           AS "total_precip_mm",
            AVG(CASE WHEN "h" BETWEEN 10 AND 17
                     THEN "cloud_pct" END)                             AS "avg_cloud_10_17_pct"
        FROM hourly
        GROUP BY "forecast_date"
    )

/* final report with snowfall / rainfall split */
SELECT
    d."forecast_date",
    d."max_temp_f",
    d."min_temp_f",
    d."avg_temp_f",
    d."total_precip_mm",
    d."avg_cloud_10_17_pct",
    CASE WHEN d."avg_temp_f" < 32  THEN d."total_precip_mm" END AS "total_snow_mm",
    CASE WHEN d."avg_temp_f" >= 32 THEN d."total_precip_mm" END AS "total_rain_mm"
FROM daily d
ORDER BY d."forecast_date";