/*---------------------------------------------------------------
  ERCOT Daily Market-Dynamics  |  01-Oct-2022
-----------------------------------------------------------------*/
WITH
/*---------------------------------------------------------------
  1) Build a 24-row hourly skeleton for the report date
-----------------------------------------------------------------*/
hours AS (
    SELECT
        DATEADD(hour, seq4(), '2022-10-01'::date) AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
/*----------------------------------------------------------------
  2) Day-ahead & Real-time LMPs  (price-node 10000697078)
----------------------------------------------------------------*/
prices AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        MAX("TIMEZONE")                AS "TIMEZONE",
        MAX("DALMP")                   AS "DALMP",
        MAX("RTLMP")                   AS "RTLMP"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DART_PRICES_SAMPLE"
    WHERE  "OBJECTID" = 10000697078
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
),
/*----------------------------------------------------------------
  3) Load-zone 10000712973  |  Forecast & actual load
----------------------------------------------------------------*/
load_fcst AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        MAX("VALUE")                   AS "LOAD_FORECAST",
        MAX("PUBLISHDATE")             AS "LOAD_FCST_PUBLISHDATE"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 19060           -- 7-day load forecast
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
),
load_rt AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        MAX("VALUE")                   AS "RTLOAD"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_LOAD_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 9641            -- actual load
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
),
/*----------------------------------------------------------------
  4) Wind  (forecast dtid 9285, actual dtid 16)
----------------------------------------------------------------*/
wind_fcst AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                   AS "WIND_GEN_FORECAST",
        MAX("PUBLISHDATE")             AS "WIND_FCST_PUBLISHDATE"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 9285
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
),
wind_act AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                   AS "WIND_GEN"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 16
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
),
/*----------------------------------------------------------------
  5) Solar (forecast dtid 662, actual dtid 650)
----------------------------------------------------------------*/
solar_fcst AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                   AS "SOLAR_GEN_FORECAST",
        MAX("PUBLISHDATE")             AS "SOLAR_FCST_PUBLISHDATE"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 662
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
),
solar_act AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        AVG("VALUE")                   AS "SOLAR_GEN"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 650
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
),
/*----------------------------------------------------------------
  6) Peak / off-peak flags (if available)
----------------------------------------------------------------*/
iso_flags AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME") AS "DATETIME",
        MAX("ONPEAK")                  AS "ONPEAK",
        MAX("OFFPEAK")                 AS "OFFPEAK",
        MAX("WEPEAK")                  AS "WEPEAK",
        MAX("WDPEAK")                  AS "WDPEAK",
        MAX("DATETIME_UTC")            AS "DATETIME_UTC"
    FROM   "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."ISO_MARKET_TIMES_SAMPLE"
    WHERE  "ISO" = 'ERCOT'
      AND  DATE("DATETIME") = '2022-10-01'
    GROUP  BY DATE_TRUNC('hour', "DATETIME")
)
/*----------------------------------------------------------------
  7) Final Assembly
----------------------------------------------------------------*/
SELECT
    h."DATETIME",
    COALESCE(f."DATETIME_UTC",
             CONVERT_TIMEZONE('America/Chicago', 'UTC', h."DATETIME")) AS "DATETIME_UTC",
    COALESCE(p."TIMEZONE", 'CDT')                AS "TIMEZONE",
    f."ONPEAK",
    f."OFFPEAK",
    f."WEPEAK",
    f."WDPEAK",
    p."DALMP",
    p."RTLMP",
    lf."LOAD_FORECAST",
    lf."LOAD_FCST_PUBLISHDATE",
    lr."RTLOAD",
    wf."WIND_GEN_FORECAST",
    wf."WIND_FCST_PUBLISHDATE",
    wa."WIND_GEN",
    sf."SOLAR_GEN_FORECAST",
    sf."SOLAR_FCST_PUBLISHDATE",
    sa."SOLAR_GEN",
    /* derived */
    NVL(lf."LOAD_FORECAST",0)
      - NVL(wf."WIND_GEN_FORECAST",0)
      - NVL(sf."SOLAR_GEN_FORECAST",0)           AS "NET_LOAD_FORECAST",
    NVL(lr."RTLOAD",0)
      - NVL(wa."WIND_GEN",0)
      - NVL(sa."SOLAR_GEN",0)                    AS "NET_LOAD_REALTIME"
FROM       hours      h
LEFT JOIN  prices     p  ON h."DATETIME" = p."DATETIME"
LEFT JOIN  iso_flags  f  ON h."DATETIME" = f."DATETIME"
LEFT JOIN  load_fcst  lf ON h."DATETIME" = lf."DATETIME"
LEFT JOIN  load_rt    lr ON h."DATETIME" = lr."DATETIME"
LEFT JOIN  wind_fcst  wf ON h."DATETIME" = wf."DATETIME"
LEFT JOIN  wind_act   wa ON h."DATETIME" = wa."DATETIME"
LEFT JOIN  solar_fcst sf ON h."DATETIME" = sf."DATETIME"
LEFT JOIN  solar_act  sa ON h."DATETIME" = sa."DATETIME"
ORDER BY h."DATETIME";