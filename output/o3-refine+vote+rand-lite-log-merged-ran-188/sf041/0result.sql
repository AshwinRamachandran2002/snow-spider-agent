/* -------------------------------------------------------------------
   ERCOT – Daily Market-Dynamics Report
   Revised to use a date that exists in the sample data: 2023-03-31
   (local ERCOT time).  Returns 24 hourly rows.
------------------------------------------------------------------- */
WITH
/* -----------------------------------------------------------------
   1)  ISO calendar – creates the hourly “clock” & peak flags.
   ----------------------------------------------------------------- */
iso_hr AS (
    SELECT
        "ISO",
        "DATETIME",                 -- local ERCOT time
        "TIMEZONE",
        "DATETIME_UTC",
        "ONPEAK",
        "OFFPEAK",
        "WEPEAK",
        "WDPEAK",
        "MARKETDAY"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."ISO_MARKET_TIMES_SAMPLE"
    WHERE "ISO" = 'ERCOT'
      AND DATE("DATETIME") = '2023-03-31'
),
/* -----------------------------------------------------------------
   2)  Day-Ahead & Real-Time prices for price-node 10000697078.
   ----------------------------------------------------------------- */
prices AS (
    SELECT
        "DATETIME",
        CAST("DALMP" AS DOUBLE) AS "DALMP",
        CAST("RTLMP" AS DOUBLE) AS "RTLMP"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DART_PRICES_SAMPLE"
    WHERE "OBJECTID" = 10000697078
      AND DATE("DATETIME") = '2023-03-31'
),
/* -----------------------------------------------------------------
   3)  Load forecast – datatype 19060 for load-zone 10000712973.
   ----------------------------------------------------------------- */
ld_fcst AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS DOUBLE)                       AS "LOAD_FORECAST",
        MAX("PUBLISHDATE") OVER (PARTITION BY "DATETIME")
                                                      AS "LOAD_FCST_PUBDATE"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 19060
      AND DATE("DATETIME") = '2023-03-31'
),
/* -----------------------------------------------------------------
   4)  Actual load – datatype 9641.
   ----------------------------------------------------------------- */
ld_rt AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS DOUBLE) AS "RTLOAD"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_LOAD_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9641
      AND DATE("DATETIME") = '2023-03-31'
),
/* -----------------------------------------------------------------
   5)  Wind & Solar forecasts.
   ----------------------------------------------------------------- */
wind_fcst AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS DOUBLE)                       AS "WIND_FCST",
        MAX("PUBLISHDATE") OVER (PARTITION BY "DATETIME")
                                                      AS "WIND_FCST_PUBDATE"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 9285              -- WIND_STWPF
      AND DATE("DATETIME") = '2023-03-31'
),
solar_fcst AS (
    SELECT
        "DATETIME",
        CAST("VALUE" AS DOUBLE)                       AS "SOLAR_FCST",
        MAX("PUBLISHDATE") OVER (PARTITION BY "DATETIME")
                                                      AS "SOLAR_FCST_PUBDATE"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_FORECAST_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 662               -- solar forecast
      AND DATE("DATETIME") = '2023-03-31'
),
/* -----------------------------------------------------------------
   6)  Wind & Solar actuals – aggregated to hourly averages.
   ----------------------------------------------------------------- */
wind_act AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME")     AS "DATETIME",
        AVG(CAST("VALUE" AS DOUBLE))       AS "WIND_GEN"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 16                -- wind actual
      AND DATE("DATETIME") = '2023-03-31'
    GROUP BY 1
),
solar_act AS (
    SELECT
        DATE_TRUNC('hour', "DATETIME")     AS "DATETIME",
        AVG(CAST("VALUE" AS DOUBLE))       AS "SOLAR_GEN"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."TS_GEN_SAMPLE"
    WHERE "OBJECTID"   = 10000712973
      AND "DATATYPEID" = 650               -- solar actual
      AND DATE("DATETIME") = '2023-03-31'
    GROUP BY 1
),
/* -----------------------------------------------------------------
   7)  Friendly names for the two objects.
   ----------------------------------------------------------------- */
meta AS (
    SELECT
        MAX(CASE WHEN "OBJECTID" = 10000697078 THEN "OBJECTNAME" END)
            AS "PRICE_NODE_NAME",
        MAX(CASE WHEN "OBJECTID" = 10000712973 THEN "OBJECTNAME" END)
            AS "LOAD_ZONE_NAME"
    FROM  "YES_ENERGY__SAMPLE_DATA"."YES_ENERGY_SAMPLE"."DS_OBJECT_LIST_SAMPLE"
    WHERE "OBJECTID" IN (10000697078, 10000712973)
)
/* -----------------------------------------------------------------
   8)  Final assembly.
   ----------------------------------------------------------------- */
SELECT
    iso_hr."ISO"                             AS "iso",
    iso_hr."DATETIME"                        AS "datetime",
    iso_hr."TIMEZONE"                        AS "timezone",
    iso_hr."DATETIME_UTC"                    AS "datetime_utc",
    iso_hr."ONPEAK"                          AS "onpeak",
    iso_hr."OFFPEAK"                         AS "offpeak",
    iso_hr."WEPEAK"                          AS "wepeak",
    iso_hr."WDPEAK"                          AS "wdpeak",
    iso_hr."MARKETDAY"                       AS "marketday",

    /* price info */
    (SELECT "PRICE_NODE_NAME" FROM meta)     AS "price_node_name",
    10000697078                              AS "price_node_id",
    prices."DALMP"                           AS "dalmp",
    prices."RTLMP"                           AS "rtlmp",

    /* load info */
    (SELECT "LOAD_ZONE_NAME"  FROM meta)     AS "load_zone_name",
    10000712973                              AS "load_zone_id",
    ld_fcst."LOAD_FORECAST"                  AS "load_forecast",
    ld_fcst."LOAD_FCST_PUBDATE"              AS "load_forecast_publish_date",
    ld_rt."RTLOAD"                           AS "rtload",

    /* wind */
    wind_fcst."WIND_FCST"                    AS "wind_gen_forecast",
    wind_fcst."WIND_FCST_PUBDATE"            AS "wind_gen_forecast_publish_date",
    wind_act."WIND_GEN"                      AS "wind_gen",

    /* solar */
    solar_fcst."SOLAR_FCST"                  AS "solar_gen_forecast",
    solar_fcst."SOLAR_FCST_PUBDATE"          AS "solar_gen_forecast_publish_date",
    solar_act."SOLAR_GEN"                    AS "solar_gen",

    /* derived net-load metrics */
    ( ld_fcst."LOAD_FORECAST"
      - COALESCE(wind_fcst."WIND_FCST",  0)
      - COALESCE(solar_fcst."SOLAR_FCST",0) )    AS "net_load_forecast",

    ( ld_rt."RTLOAD"
      - COALESCE(wind_act."WIND_GEN",   0)
      - COALESCE(solar_act."SOLAR_GEN", 0) )     AS "net_load_real_time"

FROM   iso_hr
LEFT JOIN prices     USING ("DATETIME")
LEFT JOIN ld_fcst    USING ("DATETIME")
LEFT JOIN ld_rt      USING ("DATETIME")
LEFT JOIN wind_fcst  USING ("DATETIME")
LEFT JOIN solar_fcst USING ("DATETIME")
LEFT JOIN wind_act   USING ("DATETIME")
LEFT JOIN solar_act  USING ("DATETIME")
ORDER BY iso_hr."DATETIME";