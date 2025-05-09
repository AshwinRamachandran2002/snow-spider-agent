/*-----------------------------------------------------------
 ERCOT – Daily Market Dynamics Report
 Date       : 2022-10-01  (local ERCOT / CPT time)
 Price Node : OBJECTID = 10000697078   (HB_NORTH)
 Load Zone  : OBJECTID = 10000712973   (ERCOT system-wide)
 -----------------------------------------------------------*/
WITH
/* 1) Generate the 24 hourly CPT slots for 1-Oct-2022 ---------------------- */
hour_grid AS (
    SELECT
        DATEADD('hour', seq4(), TO_TIMESTAMP_NTZ('2022-10-01 00:00:00')) AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
/* 2) Overlay any existing ISO-supplied peak/off-peak flags (may be NULL) -- */
hour_slots AS (
    SELECT
        g."DATETIME",
        CONVERT_TIMEZONE('America/Chicago', 'UTC', g."DATETIME") AS "DATETIME_UTC",
        'CDT'                                                  AS "TIMEZONE",   -- Oct-01-2022 is within daylight time
        m."ONPEAK",
        m."OFFPEAK",
        m."WEPEAK",
        m."WDPEAK",
        m."MARKETDAY"
    FROM hour_grid g
    LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE" m
           ON m."ISO" = 'ERCOT'
          AND m."DATETIME" = g."DATETIME"
),
/* 3) Day-ahead and real-time LMPs for HB_NORTH --------------------------- */
prices AS (
    SELECT
        DATE_TRUNC('hour', p."DATETIME") AS "DATETIME",
        AVG(p."DALMP")                   AS "DALMP",
        AVG(p."RTLMP")                   AS "RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" p
    WHERE p."OBJECTID" = 10000697078
      AND DATE(p."DATETIME") = '2022-10-01'
    GROUP BY 1
),
/* 4) Load forecast (datatype 19060) -------------------------------------- */
load_forecast AS (
    SELECT
        lf."DATETIME",
        lf."VALUE"       AS "LOAD_FORECAST_MW",
        lf."PUBLISHDATE" AS "LOAD_FORECAST_PUBLISHDATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" lf
    WHERE lf."OBJECTID"   = 10000712973
      AND lf."DATATYPEID" = 19060
      AND DATE(lf."DATETIME") = '2022-10-01'
),
/* 5) Wind & solar forecasts --------------------------------------------- */
wind_forecast AS (
    SELECT
        wf."DATETIME",
        wf."VALUE"       AS "WIND_FORECAST_MW",
        wf."PUBLISHDATE" AS "WIND_FORECAST_PUBLISHDATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" wf
    WHERE wf."OBJECTID"   = 10000712973
      AND wf."DATATYPEID" = 9285          -- STWPF
      AND DATE(wf."DATETIME") = '2022-10-01'
),
solar_forecast AS (
    SELECT
        sf."DATETIME",
        sf."VALUE"       AS "SOLAR_FORECAST_MW",
        sf."PUBLISHDATE" AS "SOLAR_FORECAST_PUBLISHDATE"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" sf
    WHERE sf."OBJECTID"   = 10000712973
      AND sf."DATATYPEID" = 662           -- Solar forecast
      AND DATE(sf."DATETIME") = '2022-10-01'
),
/* 6) Real-time actual load ---------------------------------------------- */
actual_load AS (
    SELECT
        al."DATETIME",
        al."VALUE" AS "RT_LOAD_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE" al
    WHERE al."OBJECTID" = 10000712973
      AND DATE(al."DATETIME") = '2022-10-01'
),
/* 7) Actual wind & solar generation – averaged to hourly ----------------- */
wind_actual AS (
    SELECT
        DATE_TRUNC('hour', wa."DATETIME") AS "DATETIME",
        AVG(wa."VALUE")                  AS "WIND_ACTUAL_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" wa
    WHERE wa."OBJECTID"   = 10000712973
      AND wa."DATATYPEID" = 16            -- Wind actual
      AND DATE(wa."DATETIME") = '2022-10-01'
    GROUP BY 1
),
solar_actual AS (
    SELECT
        DATE_TRUNC('hour', sa."DATETIME") AS "DATETIME",
        AVG(sa."VALUE")                  AS "SOLAR_ACTUAL_MW"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" sa
    WHERE sa."OBJECTID"   = 10000712973
      AND sa."DATATYPEID" = 650           -- Solar actual
      AND DATE(sa."DATETIME") = '2022-10-01'
    GROUP BY 1
),
/* 8) Static object names -------------------------------------------------- */
price_node_info AS (
    SELECT
        d."OBJECTID"   AS "PRICE_NODE_ID",
        d."OBJECTNAME" AS "PRICE_NODE_NAME"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE" d
    WHERE d."OBJECTID" = 10000697078
),
load_zone_info AS (
    SELECT
        d."OBJECTID"   AS "LOAD_ZONE_ID",
        d."OBJECTNAME" AS "LOAD_ZONE_NAME"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DS_OBJECT_LIST_SAMPLE" d
    WHERE d."OBJECTID" = 10000712973
)
/* 9) Final assembled report ---------------------------------------------- */
SELECT
    h."DATETIME",
    h."DATETIME_UTC",
    h."TIMEZONE",
    h."ONPEAK",
    h."OFFPEAK",
    h."WEPEAK",
    h."WDPEAK",
    pn."PRICE_NODE_NAME",
    pn."PRICE_NODE_ID",
    lz."LOAD_ZONE_NAME",
    lz."LOAD_ZONE_ID",
    p."DALMP",
    p."RTLMP",
    lf."LOAD_FORECAST_MW",
    lf."LOAD_FORECAST_PUBLISHDATE",
    al."RT_LOAD_MW",
    wf."WIND_FORECAST_MW",
    wf."WIND_FORECAST_PUBLISHDATE",
    wa."WIND_ACTUAL_MW",
    sf."SOLAR_FORECAST_MW",
    sf."SOLAR_FORECAST_PUBLISHDATE",
    sa."SOLAR_ACTUAL_MW",
    /* --- Net-load metrics ---------------------------------------------- */
    (lf."LOAD_FORECAST_MW"
       - COALESCE(wf."WIND_FORECAST_MW", 0)
       - COALESCE(sf."SOLAR_FORECAST_MW", 0)) AS "NET_LOAD_FORECAST_MW",
    (al."RT_LOAD_MW"
       - COALESCE(wa."WIND_ACTUAL_MW", 0)
       - COALESCE(sa."SOLAR_ACTUAL_MW", 0))   AS "NET_LOAD_RT_MW"
FROM           hour_slots      h
LEFT JOIN      prices          p   ON p."DATETIME" = h."DATETIME"
LEFT JOIN      load_forecast   lf  ON lf."DATETIME" = h."DATETIME"
LEFT JOIN      actual_load     al  ON al."DATETIME" = h."DATETIME"
LEFT JOIN      wind_forecast   wf  ON wf."DATETIME" = h."DATETIME"
LEFT JOIN      wind_actual     wa  ON wa."DATETIME" = h."DATETIME"
LEFT JOIN      solar_forecast  sf  ON sf."DATETIME" = h."DATETIME"
LEFT JOIN      solar_actual    sa  ON sa."DATETIME" = h."DATETIME"
CROSS JOIN     price_node_info pn
CROSS JOIN     load_zone_info  lz
ORDER BY h."DATETIME";