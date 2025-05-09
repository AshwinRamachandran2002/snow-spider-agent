/*  ERCOT – Daily Market-Dynamics Report
    Date: 1-Oct-2022 (local ERCOT time)                                         */

WITH hours AS (                       -- guarantee 24 hourly bins for 1-Oct-2022
    SELECT
        DATEADD('hour', SEQ4(), '2022-10-01 00:00:00'::TIMESTAMP_NTZ)
        AS "DATETIME"
    FROM TABLE(GENERATOR(ROWCOUNT => 24))
),
hour_bins AS (                        -- enrich with peak flags where available
    SELECT
        h."DATETIME",
        COALESCE(imt."TIMEZONE", 'CDT') AS "TIMEZONE",
        imt."ONPEAK",
        imt."OFFPEAK",
        imt."WEPEAK",
        imt."WDPEAK"
    FROM hours h
    LEFT JOIN YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."ISO_MARKET_TIMES_SAMPLE" imt
           ON imt."ISO" = 'ERCOT'
          AND imt."DATETIME" = h."DATETIME"
),
/*──────────────────────────────  PRICES  ──────────────────────────────*/
price_data AS (
    SELECT
        dp."DATETIME",
        dp."DALMP",
        dp."RTLMP"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."DART_PRICES_SAMPLE" dp
    WHERE dp."OBJECTID" = 10000697078            -- HB_NORTH hub
      AND dp."DATETIME" >= '2022-10-01 00:00:00'
      AND dp."DATETIME" <  '2022-10-02 00:00:00'
),
/*──────────────────────────  LOAD FORECAST  ───────────────────────────*/
load_forecast AS (
    SELECT
        f."DATETIME",
        f."VALUE"       AS "load_forecast_mw",
        f."PUBLISHDATE" AS "load_forecast_publishdate"
    FROM (
        SELECT
            f.*,
            ROW_NUMBER() OVER (PARTITION BY f."DATETIME"
                               ORDER BY f."PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
        WHERE f."OBJECTID"   = 10000712973      -- NORTH (ERCOT) load-zone
          AND f."DATATYPEID" = 19060            -- hourly load forecast
          AND f."DATETIME"  >= '2022-10-01 00:00:00'
          AND f."DATETIME"  <  '2022-10-02 00:00:00'
    ) f WHERE rn = 1
),
/*──────────────────────────  WIND FORECAST  ───────────────────────────*/
wind_forecast AS (
    SELECT
        f."DATETIME",
        f."VALUE"       AS "wind_forecast_mw",
        f."PUBLISHDATE" AS "wind_forecast_publishdate"
    FROM (
        SELECT
            f.*,
            ROW_NUMBER() OVER (PARTITION BY f."DATETIME"
                               ORDER BY f."PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
        WHERE f."OBJECTID"   = 10000712973
          AND f."DATATYPEID" = 9285             -- STWPF wind forecast
          AND f."DATETIME"  >= '2022-10-01 00:00:00'
          AND f."DATETIME"  <  '2022-10-02 00:00:00'
    ) f WHERE rn = 1
),
/*──────────────────────────  SOLAR FORECAST  ──────────────────────────*/
solar_forecast AS (
    SELECT
        f."DATETIME",
        f."VALUE"       AS "solar_forecast_mw",
        f."PUBLISHDATE" AS "solar_forecast_publishdate"
    FROM (
        SELECT
            f.*,
            ROW_NUMBER() OVER (PARTITION BY f."DATETIME"
                               ORDER BY f."PUBLISHDATE" DESC) AS rn
        FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_FORECAST_SAMPLE" f
        WHERE f."OBJECTID"   = 10000712973
          AND f."DATATYPEID" = 662              -- solar forecast
          AND f."DATETIME"  >= '2022-10-01 00:00:00'
          AND f."DATETIME"  <  '2022-10-02 00:00:00'
    ) f WHERE rn = 1
),
/*────────────────────────────  ACTUAL LOAD  ───────────────────────────*/
actual_load AS (
    SELECT
        l."DATETIME",
        l."VALUE" AS "rtload_mw"
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_LOAD_SAMPLE" l
    WHERE l."OBJECTID"   = 10000712973
      AND l."DATATYPEID" = 9641               -- actual hourly load
      AND l."DATETIME"  >= '2022-10-01 00:00:00'
      AND l."DATETIME"  <  '2022-10-02 00:00:00'
),
/*───────────────────────────  ACTUAL WIND  ────────────────────────────*/
actual_wind AS (
    SELECT
        DATE_TRUNC('hour', g."DATETIME") AS "DATETIME",
        AVG(g."VALUE")                  AS "wind_actual_mw"  -- hourly avg
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" g
    WHERE g."OBJECTID"   = 10000712973
      AND g."DATATYPEID" = 16             -- actual wind generation
      AND g."DATETIME"  >= '2022-10-01 00:00:00'
      AND g."DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY DATE_TRUNC('hour', g."DATETIME")
),
/*───────────────────────────  ACTUAL SOLAR  ───────────────────────────*/
actual_solar AS (
    SELECT
        DATE_TRUNC('hour', g."DATETIME") AS "DATETIME",
        AVG(g."VALUE")                  AS "solar_actual_mw" -- hourly avg
    FROM YES_ENERGY__SAMPLE_DATA.YES_ENERGY_SAMPLE."TS_GEN_SAMPLE" g
    WHERE g."OBJECTID"   = 10000712973
      AND g."DATATYPEID" = 650            -- actual solar generation
      AND g."DATETIME"  >= '2022-10-01 00:00:00'
      AND g."DATETIME"  <  '2022-10-02 00:00:00'
    GROUP BY DATE_TRUNC('hour', g."DATETIME")
)
/*──────────────────────────────  FINAL  ───────────────────────────────*/
SELECT
    hb."DATETIME"                                       AS "datetime",
    hb."TIMEZONE"                                       AS "timezone",
    hb."ONPEAK",
    hb."OFFPEAK",
    hb."WEPEAK",
    hb."WDPEAK",
    pd."DALMP",
    pd."RTLMP",
    lf."load_forecast_mw",
    lf."load_forecast_publishdate",
    al."rtload_mw",
    wf."wind_forecast_mw",
    wf."wind_forecast_publishdate",
    aw."wind_actual_mw",
    sf."solar_forecast_mw",
    sf."solar_forecast_publishdate",
    asol."solar_actual_mw",
    /* ── Derived KPIs ── */
    ( lf."load_forecast_mw"
        - COALESCE(wf."wind_forecast_mw", 0)
        - COALESCE(sf."solar_forecast_mw", 0) )        AS "net_load_forecast",
    ( al."rtload_mw"
        - COALESCE(aw."wind_actual_mw", 0)
        - COALESCE(asol."solar_actual_mw", 0) )        AS "net_load_real_time"
FROM hour_bins            hb
LEFT JOIN price_data      pd   ON pd."DATETIME" = hb."DATETIME"
LEFT JOIN load_forecast   lf   ON lf."DATETIME" = hb."DATETIME"
LEFT JOIN actual_load     al   ON al."DATETIME" = hb."DATETIME"
LEFT JOIN wind_forecast   wf   ON wf."DATETIME" = hb."DATETIME"
LEFT JOIN actual_wind     aw   ON aw."DATETIME" = hb."DATETIME"
LEFT JOIN solar_forecast  sf   ON sf."DATETIME" = hb."DATETIME"
LEFT JOIN actual_solar    asol ON asol."DATETIME" = hb."DATETIME"
ORDER BY hb."DATETIME";