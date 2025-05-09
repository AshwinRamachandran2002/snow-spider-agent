/*--------------------------------------------------------------
  ERCOT – Daily Market-Dynamics Report
  Date Covered :  2022-10-01  (local ERCOT time)
  Price Node   :  OBJECTID 10000697078   (HB_NORTH)
  Load Zone    :  OBJECTID 10000712973
--------------------------------------------------------------*/
WITH
/*-----------------------------------------------------------------
  1) Create a 24-hour skeleton for 1-Oct-2022 so the query
     always returns rows even if a source table is missing data.
-----------------------------------------------------------------*/
hours AS (
    SELECT
        DATEADD(HOUR, SEQ4(), '2022-10-01 00:00:00') AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
/*-----------------------------------------------------------------
  2) Derive peak / off-peak flags directly (independent of
     ISO_MARKET_TIMES_SAMPLE, which contains no records for 2022-10-01
     in the sample data).
-----------------------------------------------------------------*/
peak AS (
    SELECT
        h."DATETIME",
        -- local ERCOT time code (DST in effect on 1-Oct-2022)
        'CDT'                                                       AS "TIMEZONE",
        CONVERT_TIMEZONE('America/Chicago','UTC',h."DATETIME")      AS "DATETIME_UTC",
        /* peak classifications */
        CASE
            WHEN DAYOFWEEK(h."DATETIME") IN (2,3,4,5,6)   -- Mon-Fri
                 AND DATE_PART('hour',h."DATETIME") BETWEEN 7 AND 21
                 THEN 1
            WHEN DAYOFWEEK(h."DATETIME") IN (1,7)         -- Sun / Sat
                 AND DATE_PART('hour',h."DATETIME") BETWEEN 7 AND 21
                 THEN 1
            ELSE 0
        END                                                         AS "ONPEAK",
        CASE
            WHEN DAYOFWEEK(h."DATETIME") IN (2,3,4,5,6)
                 AND DATE_PART('hour',h."DATETIME") BETWEEN 7 AND 21
                 THEN 0
            WHEN DAYOFWEEK(h."DATETIME") IN (1,7)
                 AND DATE_PART('hour',h."DATETIME") BETWEEN 7 AND 21
                 THEN 0
            ELSE 1
        END                                                         AS "OFFPEAK",
        CASE
            WHEN DAYOFWEEK(h."DATETIME") IN (1,7)
                 AND DATE_PART('hour',h."DATETIME") BETWEEN 7 AND 21
                 THEN 1
            ELSE 0
        END                                                         AS "WEPEAK",
        CASE
            WHEN DAYOFWEEK(h."DATETIME") IN (2,3,4,5,6)
                 AND DATE_PART('hour',h."DATETIME") BETWEEN 7 AND 21
                 THEN 1
            ELSE 0
        END                                                         AS "WDPEAK",
        DATE_TRUNC('day',h."DATETIME")                               AS "MARKETDAY"
    FROM hours h
),
/*-----------------------------------------------------------------
  3) Pull data from individual source tables (all LEFT joined).
-----------------------------------------------------------------*/
prices AS (
    SELECT
        "DATETIME",
        "DALMP",
        "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND "RTFINAL"  = 'Y'
      AND "DATETIME" >= '2022-10-01 00:00:00'
      AND "DATETIME" <  '2022-10-02 00:00:00'
),
load_fcst AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "LOAD_FORECAST",
        "PUBLISHDATE" AS "LOAD_FCST_PUBLISH_DATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 19060
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),
load_act AS (
    SELECT
        "DATETIME",
        "VALUE" AS "RTLOAD"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9641
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),
wind_fcst AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "WIND_FCST",
        "PUBLISHDATE" AS "WIND_FCST_PUBLISH_DATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9285  -- STWPF
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),
wind_act AS (
    SELECT
        DATE_TRUNC('HOUR',"DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "WIND_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16   -- actual wind
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY DATE_TRUNC('HOUR',"DATETIME")
),
solar_fcst AS (
    SELECT
        "DATETIME",
        "VALUE"       AS "SOLAR_FCST",
        "PUBLISHDATE" AS "SOLAR_FCST_PUBLISH_DATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 662  -- solar forecast
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
),
solar_act AS (
    SELECT
        DATE_TRUNC('HOUR',"DATETIME") AS "DATETIME",
        AVG("VALUE")                  AS "SOLAR_GEN"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650  -- actual solar
      AND "DATETIME"  >= '2022-10-01 00:00:00'
      AND "DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY DATE_TRUNC('HOUR',"DATETIME")
),
/*-----------------------------------------------------------------
  4) Object descriptions (1 record each).
-----------------------------------------------------------------*/
price_node AS (
    SELECT
        "OBJECTID"   AS "PRICE_NODE_ID",
        "OBJECTNAME" AS "PRICE_NODE_NAME"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE"
    WHERE "OBJECTID" = 10000697078
),
load_zone AS (
    SELECT
        "OBJECTID"   AS "LOAD_ZONE_ID",
        "OBJECTNAME" AS "LOAD_ZONE_NAME"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE"
    WHERE "OBJECTID" = 10000712973
    LIMIT 1
)
/*-----------------------------------------------------------------
  5) Assemble the report.
-----------------------------------------------------------------*/
SELECT
    'ERCOT'                                          AS "ISO",
    p."DATETIME",
    p."TIMEZONE",
    p."DATETIME_UTC",
    p."ONPEAK",
    p."OFFPEAK",
    p."WEPEAK",
    p."WDPEAK",
    p."MARKETDAY",
    pn."PRICE_NODE_NAME",
    pn."PRICE_NODE_ID",
    pr."DALMP",
    pr."RTLMP",
    lz."LOAD_ZONE_NAME",
    lz."LOAD_ZONE_ID",
    lf."LOAD_FORECAST",
    lf."LOAD_FCST_PUBLISH_DATE",
    la."RTLOAD",
    wf."WIND_FCST"               AS "WIND_GEN_FORECAST",
    wf."WIND_FCST_PUBLISH_DATE"  AS "WIND_GEN_FCST_PUBLISH_DATE",
    wa."WIND_GEN",
    sf."SOLAR_FCST"              AS "SOLAR_GEN_FORECAST",
    sf."SOLAR_FCST_PUBLISH_DATE" AS "SOLAR_GEN_FCST_PUBLISH_DATE",
    sa."SOLAR_GEN",
    /* net-load calculations */
    (lf."LOAD_FORECAST"
         - COALESCE(wf."WIND_FCST",0)
         - COALESCE(sf."SOLAR_FCST",0))               AS "NET_LOAD_FORECAST",
    (la."RTLOAD"
         - COALESCE(wa."WIND_GEN",0)
         - COALESCE(sa."SOLAR_GEN",0))                AS "NET_LOAD_REAL_TIME"
FROM peak p
LEFT JOIN prices     pr ON p."DATETIME" = pr."DATETIME"
LEFT JOIN load_fcst  lf ON p."DATETIME" = lf."DATETIME"
LEFT JOIN load_act   la ON p."DATETIME" = la."DATETIME"
LEFT JOIN wind_fcst  wf ON p."DATETIME" = wf."DATETIME"
LEFT JOIN wind_act   wa ON p."DATETIME" = wa."DATETIME"
LEFT JOIN solar_fcst sf ON p."DATETIME" = sf."DATETIME"
LEFT JOIN solar_act  sa ON p."DATETIME" = sa."DATETIME"
CROSS JOIN price_node pn
CROSS JOIN load_zone  lz
ORDER BY p."DATETIME";