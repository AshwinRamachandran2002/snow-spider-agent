/*========================================================
 ERCOT – DAILY MARKET DYNAMICS REPORT
 Date : 01‑Oct‑2022   (local Central time)
========================================================*/
WITH
/*-------------------------------------------------------
0) 24‑Hour Skeleton (local time – Central)
-------------------------------------------------------*/
hours AS (
    SELECT
        DATEADD(hour, SEQ4(), '2022-10-01 00:00:00')      AS "DATETIME"      -- local CT
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/*-------------------------------------------------------
1) CLASSIFY PEAK BUCKETS
-------------------------------------------------------*/
time_buckets AS (
    SELECT
        h."DATETIME",
        DATEADD(hour, 5, h."DATETIME")                   AS "DATETIME_UTC",   -- CDT is UTC‑5 on 2022‑10‑01
        /* weekday number: 1=Sunday … 7=Saturday          */
        DAYOFWEEK(h."DATETIME")                          AS "DW",
        EXTRACT(hour FROM h."DATETIME")                  AS "HR"
    FROM hours h
),
flags AS (
    SELECT
        "DATETIME",
        "DATETIME_UTC",
        /* OFFPEAK = hrs 23,00‑05  (all days)             */
        CASE WHEN "HR" IN (0,1,2,3,4,5,23)                THEN 1 ELSE 0 END    AS "OFFPEAK",
        /* WDPEAK = weekday (Mon‑Fri) hrs 07‑22            */
        CASE WHEN "DW" BETWEEN 2 AND 6 
              AND "HR" BETWEEN 7 AND 22                   THEN 1 ELSE 0 END    AS "WDPEAK",
        /* WEPEAK = weekend (Sat‑Sun) hrs 07‑22            */
        CASE WHEN "DW" IN (1,7)
              AND "HR" BETWEEN 7 AND 22                   THEN 1 ELSE 0 END    AS "WEPEAK"
    FROM time_buckets
),

/*-------------------------------------------------------
2) PRICES  (node 10000697078)
-------------------------------------------------------*/
prices AS (
    SELECT
        "DATETIME",
        "DALMP",
        "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.DART_PRICES_SAMPLE
    WHERE "OBJECTID" = 10000697078
      AND "DATETIME" >= '2022-10-01 00:00:00'
      AND "DATETIME" <  '2022-10-02 00:00:00'
),

/*-------------------------------------------------------
3) LOAD  – Forecast (datatypeid 19060) & Actual (9641)
-------------------------------------------------------*/
load_fcst AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "LOAD_FORECAST",
        "PUBLISHDATE" AS "LOAD_FORECAST_PUBLISHDATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 19060          -- Hourly 7‑day system load forecast
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),
load_actual AS (
    SELECT
        "DATETIME",
        "VALUE" AS "RTLOAD"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_LOAD_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9641
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),

/*-------------------------------------------------------
4) WIND  – Forecast (9285) & Actual (16)
-------------------------------------------------------*/
wind_fcst AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "WIND_GEN_FORECAST",
        "PUBLISHDATE" AS "WIND_FCST_PUBLISHDATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9285
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),
wind_actual AS (
    SELECT
        "DATETIME",
        "VALUE" AS "WIND_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),

/*-------------------------------------------------------
5) SOLAR – Forecast (662) & Actual (650)
-------------------------------------------------------*/
solar_fcst AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "SOLAR_GEN_FORECAST",
        "PUBLISHDATE" AS "SOLAR_FCST_PUBLISHDATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 662
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),
solar_actual AS (
    SELECT
        "DATETIME",
        "VALUE" AS "SOLAR_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
)

/*-------------------------------------------------------
6) ASSEMBLE FINAL REPORT
-------------------------------------------------------*/
SELECT
    f."DATETIME",
    f."DATETIME_UTC",
    'ERCOT'                                              AS "ISO",

    /* Peak‑bucket flags */
    /* ONPEAK (ERCOT 16‑hr) = WDPEAK ; set explicitly   */
    f."WDPEAK"                                           AS "ONPEAK",
    f."OFFPEAK",
    f."WEPEAK",
    f."WDPEAK",

    /* Prices ($/MWh) */
    p."DALMP",
    p."RTLMP",

    /* Load (MW) */
    lf."LOAD_FORECAST",
    lf."LOAD_FORECAST_PUBLISHDATE",
    la."RTLOAD",

    /* Wind (MW) */
    wf."WIND_GEN_FORECAST",
    wf."WIND_FCST_PUBLISHDATE",
    wa."WIND_GEN",

    /* Solar (MW) */
    sf."SOLAR_GEN_FORECAST",
    sf."SOLAR_FCST_PUBLISHDATE",
    sa."SOLAR_GEN",

    /* Net‑Load Metrics (MW) */
    lf."LOAD_FORECAST"
          - (COALESCE(wf."WIND_GEN_FORECAST",0)
           + COALESCE(sf."SOLAR_GEN_FORECAST",0))        AS "NET_LOAD_FORECAST",

    la."RTLOAD"
          - (COALESCE(wa."WIND_GEN",0)
           + COALESCE(sa."SOLAR_GEN",0))                 AS "NET_LOAD_REALTIME"

FROM flags            f
LEFT JOIN prices       p  USING ("DATETIME")
LEFT JOIN load_fcst    lf USING ("DATETIME")
LEFT JOIN load_actual  la USING ("DATETIME")
LEFT JOIN wind_fcst    wf USING ("DATETIME")
LEFT JOIN wind_actual  wa USING ("DATETIME")
LEFT JOIN solar_fcst   sf USING ("DATETIME")
LEFT JOIN solar_actual sa USING ("DATETIME")

ORDER BY f."DATETIME" ASC;