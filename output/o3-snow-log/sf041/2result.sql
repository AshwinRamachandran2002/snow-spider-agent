/*-----------------------------------------------------------
  ERCOT – Daily Market-Dynamics Report (October 1 , 2022)
  (returns 24 hourly rows even when some source tables
   contain no data for the requested date)
-----------------------------------------------------------*/
WITH
/* ─────────────────────────── 0.  24-hour skeleton for 2022-10-01 */
hrs AS (
    SELECT
        DATEADD(hour, seq4(),
                TO_TIMESTAMP_NTZ('2022-10-01 00:00:00')
        )                               AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),

/* ─────────────────────────── 1.  ISO-market-time attributes  */
iso_times AS (
    SELECT  "DATETIME",
            "TIMEZONE",
            "DATETIME_UTC",
            "ONPEAK",
            "OFFPEAK",
            "WEPEAK",
            "WDPEAK",
            "MARKETDAY"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.ISO_MARKET_TIMES_SAMPLE
    WHERE   "ISO" = 'ERCOT'
      AND   DATE("DATETIME") = '2022-10-01'
),

/* ─────────────────────────── 2.  DA / RT prices (HB_NORTH) */
prices AS (
    SELECT  "DATETIME",
            "DALMP",
            "RTLMP"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.DART_PRICES_SAMPLE
    WHERE   "OBJECTID" = 10000697078
      AND   DATE("DATETIME") = '2022-10-01'
),

/* ─────────────────────────── 3.  Load forecast (keep latest publish) */
load_fc AS (
    SELECT  "DATETIME",
            "VALUE"        AS "LOAD_FORECAST",
            "PUBLISHDATE"  AS "LOAD_FC_PUBLISHDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC) AS rn
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 19060
      AND   DATE("DATETIME") = '2022-10-01'
),

/* ─────────────────────────── 4.  Actual hourly load */
load_rt AS (
    SELECT  "DATETIME",
            "VALUE" AS "RTLOAD"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_LOAD_SAMPLE
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 9641
      AND   DATE("DATETIME") = '2022-10-01'
),

/* ─────────────────────────── 5.  Wind forecast / actual */
wind_fc AS (
    SELECT  "DATETIME",
            "VALUE"       AS "WIND_FC_MW",
            "PUBLISHDATE" AS "WIND_FC_PUBLISHDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC) AS rn
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 9285
      AND   DATE("DATETIME") = '2022-10-01'
),
wind_rt AS (
    SELECT  "DATETIME",
            "VALUE" AS "WIND_RT_MW"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_GEN_SAMPLE
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 16
      AND   DATE("DATETIME") = '2022-10-01'
),

/* ─────────────────────────── 6.  Solar forecast / actual */
solar_fc AS (
    SELECT  "DATETIME",
            "VALUE"       AS "SOLAR_FC_MW",
            "PUBLISHDATE" AS "SOLAR_FC_PUBLISHDATE",
            ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                               ORDER BY "PUBLISHDATE" DESC) AS rn
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 662
      AND   DATE("DATETIME") = '2022-10-01'
),
solar_rt AS (
    SELECT  "DATETIME",
            "VALUE" AS "SOLAR_RT_MW"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE.TS_FORECAST_SAMPLE
    WHERE   "OBJECTID"   = 10000712973
      AND   "DATATYPEID" = 650
      AND   DATE("DATETIME") = '2022-10-01'
),

/* ─────────────────────────── 7.  Static names for node & zone */
price_node AS (
    SELECT  10000697078                          AS "PRICE_NODE_ID",
            'HB_NORTH'                           AS "PRICE_NODE_NAME"
),
load_zone AS (
    SELECT  10000712973                          AS "LOAD_ZONE_ID",
            'ERCOT'                              AS "LOAD_ZONE_NAME"
)

/* ─────────────────────────── 8.  Final assembly */
SELECT
        'ERCOT'                                   AS "ISO",
        h."DATETIME"                              AS "DATETIME",
        COALESCE(t."TIMEZONE" , 'CPT')            AS "TIMEZONE",
        COALESCE(t."DATETIME_UTC",
                 CONVERT_TIMEZONE('America/Chicago','UTC', h."DATETIME"))
                                                  AS "DATETIME_UTC",
        COALESCE(t."ONPEAK" ,0)                   AS "ONPEAK",
        COALESCE(t."OFFPEAK",0)                   AS "OFFPEAK",
        COALESCE(t."WEPEAK" ,0)                   AS "WEPEAK",
        COALESCE(t."WDPEAK" ,0)                   AS "WDPEAK",
        t."MARKETDAY"                             AS "MARKETDAY",
        pn."PRICE_NODE_NAME",
        pn."PRICE_NODE_ID",
        pr."DALMP",
        pr."RTLMP",
        lz."LOAD_ZONE_NAME",
        lz."LOAD_ZONE_ID",
        lf."LOAD_FORECAST",
        lf."LOAD_FC_PUBLISHDATE",
        lr."RTLOAD",
        wf."WIND_FC_MW",
        wf."WIND_FC_PUBLISHDATE",
        wr."WIND_RT_MW",
        sf."SOLAR_FC_MW",
        sf."SOLAR_FC_PUBLISHDATE",
        sr."SOLAR_RT_MW",
        /* -------- Net-load computations -------- */
        (lf."LOAD_FORECAST"
         - COALESCE(wf."WIND_FC_MW",0)
         - COALESCE(sf."SOLAR_FC_MW",0))          AS "NET_LOAD_FORECAST",
        (lr."RTLOAD"
         - COALESCE(wr."WIND_RT_MW",0)
         - COALESCE(sr."SOLAR_RT_MW",0))          AS "NET_LOAD_REAL_TIME"
FROM        hrs                      h
LEFT JOIN   iso_times               t  ON t."DATETIME" = h."DATETIME"
LEFT JOIN   prices                  pr ON pr."DATETIME" = h."DATETIME"
LEFT JOIN   load_fc                 lf ON lf."DATETIME" = h."DATETIME" AND lf.rn = 1
LEFT JOIN   load_rt                 lr ON lr."DATETIME" = h."DATETIME"
LEFT JOIN   wind_fc                 wf ON wf."DATETIME" = h."DATETIME" AND wf.rn = 1
LEFT JOIN   wind_rt                 wr ON wr."DATETIME" = h."DATETIME"
LEFT JOIN   solar_fc                sf ON sf."DATETIME" = h."DATETIME" AND sf.rn = 1
LEFT JOIN   solar_rt                sr ON sr."DATETIME" = h."DATETIME"
CROSS JOIN  price_node              pn
CROSS JOIN  load_zone               lz
ORDER BY    h."DATETIME";