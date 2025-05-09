/*--------------------------------------------------------------------
   ERCOT – Daily Market-Dynamics Report
   Automatically targets the first calendar day for which every 
   required series (prices, load, forecasts, generation, peak flags) 
   is available in the sample data.  
--------------------------------------------------------------------*/
WITH
/* --------- 1)  First common market-day --------------------------- */
base_day AS (
    SELECT MIN(CAST("DATETIME" AS DATE)) AS "DAY"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE"
    WHERE  "OBJECTID" = 10000697078          -- HB_NORTH
      AND  "RTFINAL"  = 'Y'
),
/* --------- 2)  Day-ahead & Real-time prices ---------------------- */
price AS (
    SELECT  p."DATETIME",
            p."TIMEZONE",
            p."DALMP",
            p."RTLMP",
            o."OBJECTNAME"  AS "PRICE_NODE_NAME",
            p."OBJECTID"    AS "PRICE_NODE_ID"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" p
    JOIN    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE" o
           ON o."OBJECTID" = p."OBJECTID"
    WHERE   p."OBJECTID"   = 10000697078
      AND   p."RTFINAL"    = 'Y'
      AND   CAST(p."DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
),
/* --------- 3)  Peak / off-peak flags ----------------------------- */
market_times AS (
    SELECT  "DATETIME",
            "TIMEZONE",
            "DATETIME_UTC",
            "ONPEAK",
            "OFFPEAK",
            "WEPEAK",
            "WDPEAK",
            "MARKETDAY"
    FROM    YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE"
    WHERE   "ISO" = 'ERCOT'
      AND   CAST("DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
),
/* --------- 4)  Load forecast (latest) --------------------------- */
lf AS (
    SELECT  "DATETIME",
            "VALUE"       AS "LOAD_FORECAST",
            "PUBLISHDATE" AS "LOAD_FORECAST_PUBLISH_DATE"
    FROM   (
            SELECT f.*,
                   ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                      ORDER BY "PUBLISHDATE" DESC) AS rn
            FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
            WHERE  f."OBJECTID"   = 10000712973    -- NORTH load zone
              AND  f."DATATYPEID" = 19060          -- Load forecast
              AND  CAST(f."DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
          )
    WHERE  rn = 1
),
/* --------- 5)  Actual load -------------------------------------- */
actual_load AS (
    SELECT "DATETIME",
           "VALUE" AS "RTLOAD"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"
    WHERE  "OBJECTID" = 10000712973
      AND  CAST("DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
),
/* --------- 6)  Wind forecast (latest) --------------------------- */
wind_f AS (
    SELECT  "DATETIME",
            "VALUE"       AS "WIND_GEN_FORECAST",
            "PUBLISHDATE" AS "WIND_GEN_FORECAST_PUBLISH_DATE"
    FROM   (
            SELECT f.*,
                   ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                      ORDER BY "PUBLISHDATE" DESC) AS rn
            FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
            WHERE  f."OBJECTID"   = 10000712973
              AND  f."DATATYPEID" = 9285            -- WIND_STWPF
              AND  CAST(f."DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
          )
    WHERE  rn = 1
),
/* --------- 7)  Wind actual -------------------------------------- */
wind_a AS (
    SELECT "DATETIME",
           "VALUE" AS "WIND_GEN"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 16             -- Actual wind
      AND  CAST("DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
),
/* --------- 8)  Solar forecast (latest) -------------------------- */
solar_f AS (
    SELECT  "DATETIME",
            "VALUE"       AS "SOLAR_GEN_FORECAST",
            "PUBLISHDATE" AS "SOLAR_GEN_FORECAST_PUBLISH_DATE"
    FROM   (
            SELECT f.*,
                   ROW_NUMBER() OVER (PARTITION BY "DATETIME"
                                      ORDER BY "PUBLISHDATE" DESC) AS rn
            FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
            WHERE  f."OBJECTID"   = 10000712973
              AND  f."DATATYPEID" = 662            -- Solar forecast
              AND  CAST(f."DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
          )
    WHERE  rn = 1
),
/* --------- 9)  Solar actual ------------------------------------- */
solar_a AS (
    SELECT "DATETIME",
           "VALUE" AS "SOLAR_GEN"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE  "OBJECTID"   = 10000712973
      AND  "DATATYPEID" = 650            -- Actual solar
      AND  CAST("DATETIME" AS DATE) = (SELECT "DAY" FROM base_day)
),
/* ---------10) Load-zone descriptor (constant row) --------------- */
load_zone AS (
    SELECT "OBJECTNAME" AS "LOAD_ZONE_NAME",
           "OBJECTID"   AS "LOAD_ZONE_ID"
    FROM   YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE"
    WHERE  "OBJECTID" = 10000712973
)
/* =========================  Final Report  ======================= */
SELECT
        'ERCOT'                               AS "ISO",
        p."DATETIME",
        p."TIMEZONE",
        mt."DATETIME_UTC",
        mt."ONPEAK",
        mt."OFFPEAK",
        mt."WEPEAK",
        mt."WDPEAK",
        mt."MARKETDAY",
        p."PRICE_NODE_NAME",
        p."PRICE_NODE_ID",
        p."DALMP",
        p."RTLMP",
        lz."LOAD_ZONE_NAME",
        lz."LOAD_ZONE_ID",
        lf."LOAD_FORECAST",
        lf."LOAD_FORECAST_PUBLISH_DATE",
        al."RTLOAD",
        wf."WIND_GEN_FORECAST",
        wf."WIND_GEN_FORECAST_PUBLISH_DATE",
        wa."WIND_GEN",
        sf."SOLAR_GEN_FORECAST",
        sf."SOLAR_GEN_FORECAST_PUBLISH_DATE",
        sa."SOLAR_GEN",
        /* ---------------- Net-load metrics ---------------------- */
        (lf."LOAD_FORECAST"
           - COALESCE(wf."WIND_GEN_FORECAST",0)
           - COALESCE(sf."SOLAR_GEN_FORECAST",0))  AS "NET_LOAD_FORECAST",
        (al."RTLOAD"
           - COALESCE(wa."WIND_GEN",0)
           - COALESCE(sa."SOLAR_GEN",0))           AS "NET_LOAD_REAL_TIME"
FROM        price         p
LEFT JOIN   market_times  mt  ON mt."DATETIME" = p."DATETIME"
LEFT JOIN   lf                 ON lf."DATETIME" = p."DATETIME"
LEFT JOIN   actual_load   al   ON al."DATETIME" = p."DATETIME"
LEFT JOIN   wind_f        wf   ON wf."DATETIME" = p."DATETIME"
LEFT JOIN   wind_a        wa   ON wa."DATETIME" = p."DATETIME"
LEFT JOIN   solar_f       sf   ON sf."DATETIME" = p."DATETIME"
LEFT JOIN   solar_a       sa   ON sa."DATETIME" = p."DATETIME"
CROSS JOIN  load_zone     lz
ORDER BY    p."DATETIME";