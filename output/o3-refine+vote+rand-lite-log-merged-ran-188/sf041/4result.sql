/*--------------------------------------------------------------------
  ERCOT – Daily Market-Dynamics Report (01-Oct-2022)
  – robust calendar generator ensures 24 hourly rows even if the
    sample tables do not contain that date in ISO_MARKET_TIMES_SAMPLE
--------------------------------------------------------------------*/
WITH
/*----------------------------------------------------------------
  1) Generate 24 hourly stamps for 2022-10-01 (ERCOT local = CDT)
----------------------------------------------------------------*/
hrs AS (
    SELECT
        DATEADD('hour', seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00')) AS "datetime"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
/*----------------------------------------------------------------
  2) Bring in ISO peak/off-peak flags when available
----------------------------------------------------------------*/
hrs_iso AS (
    SELECT
        h."datetime",
        COALESCE(imt."DATETIME_UTC",
                 CONVERT_TIMEZONE('America/Chicago', 'UTC', h."datetime"))     AS "datetime_utc",
        COALESCE(imt."TIMEZONE", 'CDT')                                        AS "timezone",
        imt."ONPEAK",
        imt."OFFPEAK",
        imt."WEPEAK",
        imt."WDPEAK",
        imt."MARKETDAY"
    FROM hrs h
    LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE" imt
           ON imt."ISO" = 'ERCOT'
          AND imt."DATETIME" = h."datetime"
),
/*----------------------------------------------------------------
  3) Prices (HB_NORTH)
----------------------------------------------------------------*/
prices AS (
    SELECT
        p."DATETIME",
        p."DALMP",
        p."RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" p
    WHERE p."OBJECTID" = 10000697078
      AND p."RTFINAL"  = 'Y'
),
/*----------------------------------------------------------------
  4) Helper: keep latest-published forecast per hour
----------------------------------------------------------------*/
latest_fcst AS (
    SELECT  f.*,
            ROW_NUMBER() OVER (PARTITION BY f."DATETIME", f."DATATYPEID"
                               ORDER BY f."PUBLISHDATE" DESC) AS rn
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
    WHERE f."OBJECTID"   = 10000712973
      AND f."DATATYPEID" IN (19060, 9285, 662)      -- load, wind, solar
),
load_fcst  AS (SELECT * FROM latest_fcst WHERE rn = 1 AND "DATATYPEID" = 19060),
wind_fcst  AS (SELECT * FROM latest_fcst WHERE rn = 1 AND "DATATYPEID" = 9285),
solar_fcst AS (SELECT * FROM latest_fcst WHERE rn = 1 AND "DATATYPEID" = 662),
/*----------------------------------------------------------------
  5) Actuals
----------------------------------------------------------------*/
load_act AS (
    SELECT "DATETIME", "VALUE" AS "load_actual_mw"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"
    WHERE  "OBJECTID" = 10000712973
),
wind_act AS (
    SELECT "DATETIME", "VALUE" AS "wind_actual_mw"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE  "OBJECTID" = 10000712973 AND "DATATYPEID" = 16
),
solar_act AS (
    SELECT "DATETIME", "VALUE" AS "solar_actual_mw"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE  "OBJECTID" = 10000712973 AND "DATATYPEID" = 650
)
/*----------------------------------------------------------------
  6) Assemble final report
----------------------------------------------------------------*/
SELECT
    h."datetime",
    h."timezone",
    h."datetime_utc",
    h."ONPEAK",
    h."OFFPEAK",
    h."WEPEAK",
    h."WDPEAK",
    /* Prices */
    pr."DALMP"                                                   AS "dalmp_$MWh",
    pr."RTLMP"                                                   AS "rtlmp_$MWh",
    /* Load */
    lf."VALUE"            AS "load_forecast_mw",
    lf."PUBLISHDATE"      AS "load_forecast_publish_date",
    la."load_actual_mw",
    /* Wind */
    wf."VALUE"            AS "wind_forecast_mw",
    wf."PUBLISHDATE"      AS "wind_forecast_publish_date",
    wa."wind_actual_mw",
    /* Solar */
    sf."VALUE"            AS "solar_forecast_mw",
    sf."PUBLISHDATE"      AS "solar_forecast_publish_date",
    sa."solar_actual_mw",
    /* Derived metrics */
    (lf."VALUE"
         - COALESCE(wf."VALUE",0)
         - COALESCE(sf."VALUE",0))                                AS "net_load_forecast_mw",
    (la."load_actual_mw"
         - COALESCE(wa."wind_actual_mw",0)
         - COALESCE(sa."solar_actual_mw",0))                      AS "net_load_real_time_mw"
FROM       hrs_iso      h
LEFT JOIN  prices       pr ON pr."DATETIME" = h."datetime"
LEFT JOIN  load_fcst    lf ON lf."DATETIME" = h."datetime"
LEFT JOIN  load_act     la ON la."DATETIME" = h."datetime"
LEFT JOIN  wind_fcst    wf ON wf."DATETIME" = h."datetime"
LEFT JOIN  wind_act     wa ON wa."DATETIME" = h."datetime"
LEFT JOIN  solar_fcst   sf ON sf."DATETIME" = h."datetime"
LEFT JOIN  solar_act    sa ON sa."DATETIME" = h."datetime"
ORDER BY   h."datetime";